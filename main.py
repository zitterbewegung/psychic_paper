#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from fastapi import FastAPI, BackgroundTasks, HTTPException, File, UploadFile
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
#from picamera import PiCamera
#from picamera.array import PiRGBArray
from PIL import Image
import cv2
import numpy as np
import time
import inky
import os

# Initialize FastAPI
app = FastAPI()

# Add CORS middleware to allow requests from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files (like favicon)
app.mount("/static", StaticFiles(directory="static"), name="static")

# Initialize the camera and the Inky display
#camera = PiCamera()
#camera.resolution = (1280, 720)  # Set resolution suitable for ID card capture
#camera.framerate = 30
#raw_capture = PiRGBArray(camera, size=camera.resolution)

# Initialize the Inky display (automatically detects connected display)
display = inky.auto()

#def capture_image():
#    """Capture an image from the PiCamera and save it locally."""
#    try:
#        print("Capturing image...")
#        camera.capture(raw_capture, format="bgr")
#        image = raw_capture.array
#
#        # Save the captured image
#        image_path = "captured_id_card.jpg"
#        cv2.imwrite(image_path, image)
#        print(f"Image saved as {image_path}")
#        return image_path
#
#    except Exception as e:
#        print(f"Error capturing image: {e}")
#        raise

def transform_image_for_display(image_path):
    """Transform the captured image to fit the Inky 4-inch display."""
    try:
        pil_image = Image.open(image_path)
        
        # Resize the image to match the Inky display resolution
        display_resolution = display.resolution
        transformed_image = pil_image.resize(display_resolution, Image.ANTIALIAS)

        # Ensure image mode matches the display color capabilities
        transformed_image = transformed_image.convert("RGB")
        transformed_image.save("transformed_image.png")  # Save transformed image

        return transformed_image

    except Exception as e:
        print(f"Error transforming image: {e}")
        raise

def display_image_on_inky(transformed_image):
    """Display the transformed image on the Pimoroni Inky display."""
    try:
        display.set_image(transformed_image)
        display.show()
        print("Image successfully displayed on the Inky screen.")
    except Exception as e:
        print(f"Error displaying image: {e}")
        raise

@app.post("/upload/")
async def upload_image(file: UploadFile = File(...), background_tasks: BackgroundTasks = None):
    """
    Endpoint to upload an image for display.
    Requires a JPEG image, rotated 90 degrees, and sized 400x640 pixels.
    """
    if not file.filename.lower().endswith(('jpeg', 'jpg')):
        raise HTTPException(status_code=400, detail="Invalid file format. Only JPEG images are supported.")

    try:
        # Save the uploaded image
        image_path = f"uploaded_{file.filename}"
        with open(image_path, "wb") as f:
            f.write(await file.read())

        # Open and validate the image
        image = Image.open(image_path)
        if image.size != (400, 640):
            raise HTTPException(status_code=400, detail="Image must be 400x640 pixels.")
        image = image.rotate(90, expand=True)  # Rotate the image by 90 degrees

        # Save the rotated image
        image.save(image_path)
        print(f"Uploaded image saved as {image_path}")

        # Add the display process to the background
        background_tasks.add_task(display_process, image_path)

        return JSONResponse(content={"status": "Image uploaded and display initiated."})

    except Exception as e:
        print(f"Error processing uploaded image: {e}")
        raise HTTPException(status_code=500, detail="Failed to process and display the uploaded image.")

def display_process(image_path):
    """Background task to transform and display the uploaded image."""
    try:
        # Transform the uploaded image to fit the Inky display
        transformed_image = transform_image_for_display(image_path)

        # Display the transformed image on the Inky screen
        display_image_on_inky(transformed_image)

    except Exception as e:
        print(f"Error during display process: {e}")

@app.get("/")
async def main():
    """Main UI with instructions and upload form."""
    content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Inky ePaper Display</title>
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
        <link rel="icon" href="/static/favicon.ico" type="image/x-icon">
        <style>
            body { margin-top: 20px; }
            .container { max-width: 600px; }
        </style>
    </head>
    <body>
        <div class="container text-center">
            <h1 class="mb-4">Psychic Paper Programmer</h1>
            <p class="mb-4">This application can be used to clone photo ID badges. Please upload a JPEG image that is rotated by 90 degrees and is 400x640 pixels.</p>
            <form action="/upload/" enctype="multipart/form-data" method="post" onsubmit="showLoading()">
                <div class="form-group">
                    <input name="file" type="file" accept="image/jpeg" class="form-control-file" required>
                </div>
                <button type="submit" class="btn btn-primary">Upload Image</button>
            </form>
            <div id="loading" style="display:none;" class="mt-3">
                <div class="spinner-border text-primary" role="status">
                    <span class="sr-only">Uploading and processing your image... Please wait!</span>
                </div>
                <p>Uploading and processing your image... Please wait!</p>
            </div>
        </div>

        <script>
            function showLoading() {
                document.getElementById('loading').style.display = 'block';
            }
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=content)

# Serve the favicon
@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return FileResponse("static/favicon.ico")

# Ensure cleanup when the application shuts down
@app.on_event("shutdown")
def shutdown_event():
    camera.close()
    print("Camera closed.")

# Entry point for running the FastAPI app with uvicorn
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
