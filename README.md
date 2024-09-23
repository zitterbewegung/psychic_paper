# psychic_paper an ePaper ID Badge Cloner

This project allows users to upload an image (JPEG format) through a FastAPI server and display it on an Inky ePaper display. It's designed to work with ID badges or other images that you want to render on a seven-color ePaper screen. The project supports automatic image orientation correction and resizing for the display resolution.

## Features

- **FastAPI-based Web Interface**: A simple web form to upload a JPEG image to be displayed on the ePaper screen.
- **Background Image Processing**: Processes image orientation based on EXIF data and resizes it to fit the ePaper screen.
- **ePaper Display Integration**: Uses the Inky Python library to render images on the Inky seven-color ePaper display.
- **CORS Support**: Allows Cross-Origin Resource Sharing (CORS) from all origins, making it easy to interact with the API from different frontends (modifiable for security reasons).

## Requirements

### Hardware
- Inky ePaper Display (seven-color or similar)
- Raspberry Pi or another device to control the ePaper display

### Software

- Python 3.x
- FastAPI
- Inky (Python library for ePaper display control)
- Uvicorn (ASGI server for FastAPI)
- Pillow (Python Imaging Library)

### Install Requirements

```bash
pip install fastapi uvicorn inky pillow
