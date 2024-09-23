import cv2
import numpy as np
from picamera2 import Picamera2
from time import sleep
from PIL import Image
from inky.auto import auto
from gpiozero import Button

# GPIO pin for the first button
BUTTON_PIN = 5

# Initialize the button
button1 = Button(BUTTON_PIN)

# Function to detect an ID badge based on contours (assuming rectangular shape)
def detect_id_badge(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edged = cv2.Canny(blurred, 50, 150)

    contours, _ = cv2.findContours(edged.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Loop over contours to find rectangles
    for contour in contours:
        approx = cv2.approxPolyDP(contour, 0.02 * cv2.arcLength(contour, True), True)
        
        # Check if the contour has 4 vertices (likely a rectangle)
        if len(approx) == 4:
            # Calculate aspect ratio and area to filter out non-badge rectangles
            (x, y, w, h) = cv2.boundingRect(approx)
            aspect_ratio = w / float(h)
            area = cv2.contourArea(contour)
            
            # A potential badge has an aspect ratio around 1.5 and sufficient area
            if 1.2 < aspect_ratio < 1.8 and area > 1000:
                # Return the bounding box of the detected badge
                return x, y, w, h
    return None

# Function to scale and display image on the Pimoroni display
def display_image_on_pimoroni(image_path):
    # Initialize Pimoroni display
    inky_display = auto()
    inky_display.set_border(inky_display.WHITE)

    # Load the image
    image = Image.open(image_path)

    # Resize the image to the display's resolution (640x400)
    image_resized = image.resize((640, 400))

    # Convert to a suitable image format for the Pimoroni display
    inky_display.set_image(image_resized)
    inky_display.show()

# Capture and process the image
def capture_and_process_image():
    print("Capturing image...")

    # Initialize the camera
    picam2 = Picamera2()

    # Configure and start the camera
    preview_config = picam2.create_preview_configuration(main={"size": (1920, 1080)})
    picam2.configure(preview_config)
    picam2.start()

    # Let the camera warm up
    sleep(2)

    # Capture an image
    image = picam2.capture_array()

    # Detect ID badge in the image
    badge_coords = detect_id_badge(image)

    if badge_coords:
        # Draw rectangle around detected badge
        x, y, w, h = badge_coords
        cv2.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        print("ID Badge detected!")

        # Save the image with the rectangle as a JPEG
        output_path = "id_badge_detected.jpg"
        cv2.imwrite(output_path, image)

        # Scale and display the image on the Pimoroni display
        display_image_on_pimoroni(output_path)
    else:
        print("No ID Badge detected.")

    # Stop the camera
    picam2.stop()

# Define the action to be triggered by the button
def button_pressed():
    capture_and_process_image()

# Assign the button press action
button1.when_pressed = button_pressed

# Keep the program running and waiting for button press
print("Waiting for button press...")
while True:
    sleep(1)
