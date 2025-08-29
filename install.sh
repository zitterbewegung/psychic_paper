#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Inky Web (Pi Zero W + 4" Inky Impression)
- FastAPI app with polished HTML UI
- Palette quantization to the Inky Impression's 7-color set (optional)
- Dithering toggle
- / : Upload form (drag & drop, palette + dither controls)
- /upload : POST (multipart) -> render to Inky (background) and show nice HTML result
- /api/upload : API JSON variant
- /uploads : static previews
"""

import os
import io
import sys
import traceback
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Tuple

from fastapi import FastAPI, UploadFile, File, BackgroundTasks, Request
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles
from PIL import Image, ImageOps, ImagePalette

# ---------------- Config ----------------
APP_TITLE = "Inky Impression Uploader"
UPLOAD_DIR = Path(os.environ.get("INKY_UPLOAD_DIR", "/var/lib/inky-web/uploads"))
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

DEFAULT_PALETTE = os.environ.get("INKY_DEFAULT_PALETTE", "none")  # none | pure-7 | muted-7
DEFAULT_DITHER = os.environ.get("INKY_DEFAULT_DITHER", "fs")      # fs | none

# --------------- Inky Display ---------------
_display = None
def get_display():
    """Lazy-init display; allow running without hardware for dev."""
    global _display
    if _display is not None:
        return _display
    try:
        # Prefer new auto()
        try:
            from inky.auto import auto
            disp = auto()
        except Exception:
            import inky
            disp = inky.auto()
        _display = disp
        return _display
    except Exception as e:
        print("[WARN] Inky display not available:", e, file=sys.stderr)
        _display = None
        return None

# ---------------- HTML Template ----------------
def page_template(title: str, body_html: str) -> HTMLResponse:
    css = """
    :root {
      --bg:#0f1115; --panel:#16181e; --muted:#7e8696;
      --accent:#5aa9ff; --accent-2:#73d2de; --ok:#38c172; --warn:#ffb020; --err:#ff5a5f;
      --text:#e6e8ee; --text-dim:#b3b7c3; --border:#232632;
    }
    * { box-sizing:border-box; }
    html, body { height:100%; margin:0; }
    body {
      background:linear-gradient(180deg, #0f1115 0%, #121420 100%);
      color:var(--text); font-family: ui-sans-serif, system-ui, -apple-system,"Segoe UI",
        Roboto,"Helvetica Neue",Arial,"Noto Sans","Liberation Sans",sans-serif;
    }
    .wrap { max-width: 960px; margin: 40px auto; padding: 24px; }
    .card { background:var(--panel); border:1px solid var(--border);
            border-radius:16px; padding:24px; box-shadow:0 20px 40px rgba(0,0,0,.25); }
    h1 { margin:0 0 12px; font-weight:700; letter-spacing:.2px; }
    p.lead { color:var(--text-dim); margin-top:0; }
    .muted { color:var(--muted); }
    .grid { display:grid; gap:16px; }
    .row { display:flex; gap:12px; align-items:center; flex-wrap:wrap; }
    .btn { display:inline-block; background:linear-gradient(135deg,var(--accent),var(--accent-2));
           color:#081018; font-weight:700; padding:12px 16px; border-radius:12px;
           border:none; text-decoration:none; cursor:pointer; transition: transform .04s ease; }
    .btn:active { transform: translateY(1px) scale(.995); }
    .btn.secondary { background:transparent; color:var(--text); border:1px solid var(--border); }
    .drop { border:2px dashed #2c3142; border-radius:16px; padding:24px; text-align:center;
            background: rgba(90,169,255,0.03); }
    .drop.dragover { border-color: var(--accent); background: rgba(90,169,255,0.08); }
    .mono { font-family: ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace; }
    .kv { display:grid; grid-template-columns: 160px 1fr; gap:8px 12px; }
    .imgprev { max-width: 100%; border-radius:12px; border:1px solid var(--border); }
    .select, .check { background:#11131a; color:var(--text); border:1px solid var(--border);
                      border-radius:12px; padding:10px 12px; min-width: 160px; }
    footer { color:var(--muted); margin-top:16px; text-align:center; font-size:12px; }
    .swatches { display:flex; gap:8px; flex-wrap:wrap; }
    .swatch { width:22px; height:22px; border-radius:6px; border:1px solid var(--border); }
    """
    html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{title}</title>
  <style>{css}</style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      {body_html}
    </div>
    <footer>Inky Impression Uploader • FastAPI on Raspberry Pi Zero W</footer>
  </div>
</body>
</html>"""
    return HTMLResponse(html)

# ---------------- Palette Stuff ----------------
# Official 7 target colors (hardware pigments on ACeP/Gallery): black, white, red, green, blue, yellow, orange
# Sources mention these seven for 4.0–7.3" Impression panels. We provide two sets:
# 1) "pure-7" sRGB primaries (easy to reason about)
# 2) "muted-7" approximations that better resemble the panel's appearance in practice (community-measured)
#   Reference for muted primaries: forum measurements (Spectra/Gallery) – red, yellow, green, blue.
#   We also pick a reasonable muted orange based on practical results.
PURE_7 = [
    (255, 255, 255),  # white
    (0, 0, 0),        # black
    (255, 0, 0),      # red
    (0, 255, 0),      # green
    (0, 0, 255),      # blue
    (255, 255, 0),    # yellow
    (255, 165, 0),    # orange (#FFA500)
]

MUTED_7 = [
    (255, 255, 255),  # white
    (0, 0, 0),        # black
    (160, 32, 32),    # red   ~ #a02020
    (96, 128, 80),    # green ~ #608050
    (80, 128, 184),   # blue  ~ #5080b8
    (240, 224, 80),   # yellow~ #f0e050
    (208, 128, 64),   # orange~ #d08040 (empirical)
]

def _build_palette_bytes(colors: Iterable[Tuple[int,int,int]]) -> List[int]:
    """Pillow expects a 768-length flat list (256 * 3). Fill remaining entries with the last color."""
    flat: List[int] = []
    for (r, g, b) in colors:
        flat.extend([int(r), int(g), int(b)])
    # Pad to 256 colors
    last = list(colors)[-1]
    while len(flat) < 256 * 3:
        flat.extend([last[0], last[1], last[2]])
    return flat[:256*3]

def _make_palette_image(colors: Iterable[Tuple[int,int,int]]) -> Image.Image:
    pal_img = Image.new("P", (1, 1))
    pal_img.putpalette(_build_palette_bytes(list(colors)))
    return pal_img

def quantize_to_palette(img: Image.Image, palette: str, dither: str) -> Image.Image:
    """Quantize to our 7-color palette; dither='fs' or 'none'."""
    if palette not in {"pure-7", "muted-7"}:
        return img
    colors = PURE_7 if palette == "pure-7" else MUTED_7
    pal_img = _make_palette_image(colors)
    # Pillow quantize with custom palette; then convert back to RGB for Inky driver
    d = Image.FLOYDSTEINBERG if dither == "fs" else Image.Dither.NONE
    q = img.convert("RGB").quantize(palette=pal_img, dither=d)
    return q.convert("RGB")

# ---------------- Helpers ----------------
def _safe_filename(orig: str) -> str:
    stem = Path(orig or "image").stem[:64].replace(" ", "_")
    ext = (Path(orig or "image.png").suffix or ".png").lower()
    if ext not in {".png",".jpg",".jpeg",".bmp",".gif"}:
        ext = ".png"
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    return f"{stem}-{ts}{ext}"

def _fit_for_display(img: Image.Image) -> Image.Image:
    disp = get_display()
    if disp is None:
        # Dev fallback: generic contain into a common Impression size
        return ImageOps.contain(img.convert("RGB"), (800, 480))
    try:
        w, h = getattr(disp, "resolution", (disp.WIDTH, disp.HEIGHT))
    except Exception:
        w, h = (disp.WIDTH, disp.HEIGHT)
    rgb = img.convert("RGB")
    fitted = ImageOps.contain(rgb, (w, h))
    out = Image.new("RGB", (w, h), (255, 255, 255))
    x = (w - fitted.width) // 2
    y = (h - fitted.height) // 2
    out.paste(fitted, (x, y))
    return out

def _render_to_inky(path: Path, palette: str, dither: str):
    disp = get_display()
    if disp is None:
        print("[WARN] No Inky detected; skipping hardware render.", file=sys.stderr)
        return
    try:
        img = Image.open(path)
        prepared = _fit_for_display(img)
        prepared = quantize_to_palette(prepared, palette=palette, dither=dither)
        disp.set_image(prepared)
        disp.show()
        print(f"[OK] Rendered to Inky: {path} palette={palette} dither={dither}")
    except Exception as e:
        print("[ERR] Failed to render to Inky:", e, file=sys.stderr)
        traceback.print_exc()

def _accept_json(request: Request) -> bool:
    accept = (request.headers.get("accept") or "").lower()
    return "application/json" in accept

# ---------------- FastAPI App ----------------
app = FastAPI(title=APP_TITLE)
if UPLOAD_DIR.exists():
    app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR.as_posix()), name="uploads")

@app.get("/", response_class=HTMLResponse)
async def index():
    # swatch preview HTML
    def swatches(hexes):
        return "".join(f'<div class="swatch" style="background:{h}"></div>' for h in hexes)

    pure_hex = ["#FFFFFF","#000000","#FF0000","#00FF00","#0000FF","#FFFF00","#FFA500"]
    muted_hex = ["#FFFFFF","#000000","#A02020","#608050","#5080B8","#F0E050","#D08040"]

    body = f"""
    <h1>{APP_TITLE}</h1>
    <p class="lead">
      Upload an image and (optionally) quantize it to the Impression's 7 colors for cleaner, more predictable output.
      <span class="muted">Tip: try <b>muted-7</b> if your reds/greens/blues look too saturated on-panel.</span>
    </p>

    <div class="grid">
      <div id="drop" class="drop">
        <p class="muted">Drag & drop an image here, or click to choose</p>
        <input id="file" type="file" accept="image/*" style="display:none" />
        <button class="btn secondary" id="chooseBtn">Choose Image</button>
      </div>

      <div class="row">
        <label>Palette:
          <select id="palette" class="select">
            <option value="none" {"selected" if DEFAULT_PALETTE=="none" else ""}>none (send RGB)</option>
            <option value="pure-7" {"selected" if DEFAULT_PALETTE=="pure-7" else ""}>pure-7 (sRGB)</option>
            <option value="muted-7" {"selected" if DEFAULT_PALETTE=="muted-7" else ""}>muted-7 (panel-tuned)</option>
          </select>
        </label>
        <label>Dither:
          <select id="dither" class="select">
            <option value="fs" {"selected" if DEFAULT_DITHER=="fs" else ""}>Floyd–Steinberg</option>
            <option value="none" {"selected" if DEFAULT_DITHER=="none" else ""}>none</option>
          </select>
        </label>
        <button id="uploadBtn" class="btn" disabled>Upload & Render</button>
        <a class="btn secondary" href="/health">Health</a>
        <a class="btn secondary" href="/uploads/" target="_blank" rel="noreferrer">View Uploads</a>
      </div>

      <div class="muted">pure-7 swatches</div>
      <div class="swatches">{swatches(pure_hex)}</div>
      <div class="muted" style="margin-top:8px;">muted-7 swatches</div>
      <div class="swatches">{swatches(muted_hex)}</div>

      <div id="preview" style="margin-top:16px;"></div>
      <div id="status" class="muted mono"></div>
    </div>

    <script>
      const drop = document.getElementById('drop');
      const fileInput = document.getElementById('file');
      const chooseBtn = document.getElementById('chooseBtn');
      const uploadBtn = document.getElementById('uploadBtn');
      const paletteSel = document.getElementById('palette');
      const ditherSel = document.getElementById('dither');
      const preview = document.getElementById('preview');
      const status = document.getElementById('status');
      let chosen = null;

      function showPreview(file) {{
        const url = URL.createObjectURL(file);
        preview.innerHTML = '<img class="imgprev" src="'+url+'" />';
      }}

      drop.addEventListener('click', () => fileInput.click());
      chooseBtn.addEventListener('click', () => fileInput.click());

      drop.addEventListener('dragover', (e) => {{ e.preventDefault(); drop.classList.add('dragover'); }});
      drop.addEventListener('dragleave', () => drop.classList.remove('dragover'));
      drop.addEventListener('drop', (e) => {{
        e.preventDefault();
        drop.classList.remove('dragover');
        if (e.dataTransfer.files && e.dataTransfer.files[0]) {{
          chosen = e.dataTransfer.files[0];
          showPreview(chosen);
          uploadBtn.disabled = false;
        }}
      }});

      fileInput.addEventListener('change', (e) => {{
        if (e.target.files && e.target.files[0]) {{
          chosen = e.target.files[0];
          showPreview(chosen);
          uploadBtn.disabled = false;
        }}
      }});

      uploadBtn.addEventListener('click', async () => {{
        if (!chosen) return;
        status.textContent = 'Uploading…';
        const form = new FormData();
        form.append('file', chosen, chosen.name || 'image.png');
        form.append('palette', paletteSel.value);
        form.append('dither', ditherSel.value);
        try {{
          const res = await fetch('/upload', {{ method: 'POST', body: form, headers: {{ 'Accept': 'text/html' }} }});
          const html = await res.text();
          document.open(); document.write(html); document.close();
        }} catch (err) {{
          status.textContent = 'Upload failed: ' + err;
        }}
      }});
    </script>
    """
    return page_template(APP_TITLE, body)

@app.get("/health")
async def health():
    disp = get_display()
    info = {
        "ok": True,
        "display_attached": bool(disp is not None),
        "upload_dir": UPLOAD_DIR.as_posix(),
        "now": datetime.now().isoformat(timespec="seconds"),
    }
    return JSONResponse(info)

@app.post("/upload", response_class=HTMLResponse)
async def upload(request: Request, background: BackgroundTasks,
                 file: UploadFile = File(...)):
    # read controls (with safe defaults)
    form = await request.form()
    palette = (form.get("palette") or DEFAULT_PALETTE).strip().lower()
    dither = (form.get("dither") or DEFAULT_DITHER).strip().lower()
    if palette not in {"none","pure-7","muted-7"}: palette = "none"
    if dither not in {"fs","none"}: dither = "fs"

    # save file
    name = _safe_filename(file.filename or "image.png")
    dest = UPLOAD_DIR / name
    raw = await file.read()
    dest.write_bytes(raw)

    # background render
    background.add_task(_render_to_inky, dest, palette, dither)

    if _accept_json(request):
        return JSONResponse({"ok": True, "saved_as": name, "path": f"/uploads/{name}",
                             "palette": palette, "dither": dither})

    # result page
    body = f"""
    <h1>Uploaded ✓</h1>
    <p class="lead">Saved as <span class="mono">{name}</span>. Rendering with
      <b>{palette}</b> palette and <b>{'Floyd–Steinberg' if dither=='fs' else 'no'}</b> dither.</p>

    <div class="kv">
      <div class="muted">Preview</div>
      <div><img class="imgprev" src="/uploads/{name}" alt="preview" /></div>
      <div class="muted">Path</div>
      <div><a class="mono" href="/uploads/{name}" target="_blank" rel="noreferrer">/uploads/{name}</a></div>
      <div class="muted">Time</div>
      <div class="mono">{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</div>
      <div class="muted">Settings</div>
      <div class="mono">palette={palette}, dither={dither}</div>
    </div>

    <div class="row" style="margin-top:16px;">
      <a class="btn" href="/">Upload Another</a>
      <a class="btn secondary" href="/uploads/">View All Uploads</a>
    </div>
    """
    return page_template("Upload Complete", body)

@app.post("/api/upload")
async def api_upload(background: BackgroundTasks,
                     file: UploadFile = File(...)):
    name = _safe_filename(file.filename or "image.png")
    dest = UPLOAD_DIR / name
    raw = await file.read()
    dest.write_bytes(raw)
    palette = DEFAULT_PALETTE
    dither = DEFAULT_DITHER
    background.add_task(_render_to_inky, dest, palette, dither)
    return JSONResponse({"ok": True, "saved_as": name, "path": f"/uploads/{name}",
                         "palette": palette, "dither": dither})

@app.get("/favicon.ico")
async def favicon():
    return PlainTextResponse("", status_code=204)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
