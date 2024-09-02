#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image, ExifTags
from io import BytesIO
import inky
import time

# Initialize FastAPI
app = FastAPI()

# Allow CORS for all origins (adjust as needed for security)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the Inky ePaper display (adjust this initialization according to your specific seven-color display)
display = inky.auto()  # Automatically detect your Inky display type and version

def process_image(image: Image.Image):
    """Process the image to correct orientation and resize it for the ePaper screen."""
    # Correct image orientation using EXIF data, if available
    try:
        for orientation in ExifTags.TAGS.keys():
            if ExifTags.TAGS[orientation] == 'Orientation':
                break
        
        exif = image._getexif()
        if exif is not None:
            orientation = exif.get(orientation, None)
            if orientation == 3:
                image = image.rotate(180, expand=True)
            elif orientation == 6:
                image = image.rotate(270, expand=True)
            elif orientation == 8:
                image = image.rotate(90, expand=True)
    except Exception as e:
        print(f"EXIF orientation correction failed: {e}")

    # Resize the image to match the display's resolution
    image = image.resize(display.resolution, Image.ANTIALIAS)
    return image

def display_image(image: Image.Image):
    """Function to display the image on the ePaper screen."""
    try:
        # Simulate some processing delay for visual feedback
        time.sleep(2)  # Optional: simulate processing delay for user feedback
        display.set_image(image)
        display.show()
        print("Image successfully displayed on the ePaper screen.")
    except Exception as e:
        print(f"Error displaying image: {e}")

@app.post("/upload/")
async def upload_image(file: UploadFile = File(...), background_tasks: BackgroundTasks = None):
    # Check if the uploaded file is a JPEG
    if not file.filename.lower().endswith(('jpeg', 'jpg')):
        raise HTTPException(status_code=400, detail="Invalid file format. Only JPEG images are supported.")
    
    try:
        # Read the image file
        contents = await file.read()
        image = Image.open(BytesIO(contents))

        # Process the image without changing its color format
        processed_image = process_image(image)

        # Add the display task to the background to not block the response
        background_tasks.add_task(display_image, processed_image)

        # Return immediate response indicating that processing has started
        return JSONResponse(content={"filename": file.filename, "status": "Image is being processed and displayed on ePaper screen."})

    except Exception as e:
        print(f"Error processing image: {e}")
        raise HTTPException(status_code=500, detail="Failed to process and display the image.")

@app.get("/")
async def main():
    # HTML Form to upload a file
    content = """
    <html>
        <head>
            <script>
                function showLoading() {
                    document.getElementById('loading').style.display = 'block';
                }
            </script>
        </head>
        <body>
            <h1>Upload a JPEG Image (640x400px)</h1>
            <form action="/upload/" enctype="multipart/form-data" method="post" onsubmit="showLoading()">
                <input name="file" type="file" accept="image/jpeg" required>
                <input type="submit" value="Upload Image">
            </form>
            <div id="loading" style="display:none;">
                <p>Uploading and processing your image... Please wait!</p>
            </div>
        </body>
    </html>
    """
    return HTMLResponse(content=content)

# Ensure this block only runs when the script is executed directly
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
