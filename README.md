# psychic_paper an ePaper ID Badge Cloner

This project allows users to upload an image (JPEG format) through a FastAPI server and display it on an Inky ePaper display. It's designed to work with ID badges or other images that you want to render on a seven-color ePaper screen. The project supports automatic image orientation correction and resizing for the display resolution.

## Features

- **FastAPI-based Web Interface**: A simple web form to upload a JPEG image to be displayed on the ePaper screen.
- **Background Image Processing**: Processes image orientation based on EXIF data and resizes it to fit the ePaper screen.
- **ePaper Display Integration**: Uses the Inky Python library to render images on the Inky seven-color ePaper display.

## Requirements

### Hardware (Bill of Materials)

### Updated Bill of Materials (BOM)

| Part Number | Description                                                                                       | Quantity | Supplier        | Unit Cost | Total Cost | Link                                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- | -------- | --------------- | --------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 001         | Waveshare 4.01inch Colorful e-Paper Display Module, 640×400 Resolution                             | 1        | Amazon          | $72.99    | $72.99     | [Link](https://www.amazon.com/Waveshare-4-01inch-Colorful-Display-640×400/dp/B0972R7F2Q)                                                        |
| 002         | Waveshare Universal e-Paper Driver Board (Supports various interfaces including Bluetooth & USB)   | 1        | Amazon          | $35.99    | $35.99     | [Link](https://www.amazon.com/Waveshare-Universal-Interface-Refreshing-Bluetooth/dp/B07RM1BBVF)                                                 |
| 003         | Professional 12-inch Industrial Tailoring Scissors                                                | 1        | Amazon          | $22.99    | $22.99     | [Link](https://www.amazon.com/Scissors-Professional-Tailoring-Industrial-Dressmakers/dp/B07Y2ZBSN1/)                                            |
| 004         | Scotch Double Sided Tape with Dispensers (Pack of 2)                                               | 1        | Amazon          | $9.29     | $9.29      | [Link](https://www.amazon.com/Scotch-Double-Sided-Tape-Dispensers/dp/B002VLA5SI/)                                                               |

### Optional Items (Choose One)

| Part Number | Description                                                 | Quantity | Supplier        | Unit Cost | Total Cost | Link                                                                                                                                       |
| ----------- | ----------------------------------------------------------- | -------- | --------------- | --------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 005A        | Proxmark3 RDV4 Kit                                          | 1        | Hacker Warehouse | $319.95   | $319.95    | [Link](https://hackerwarehouse.com/product/proxmark3-rdv4-kit/)                                                                              |
| 005B        | Flipper Zero Multi-Tool                                     | 1        | Flipper Zero     | $169.00   | $169.00    | [Link](https://flipperzero.one)                                                                                                              |
| 005C        | Proxmark3 NFC RFID Card Reader Copier                       | 1        | eBay            | $37.95    | $37.95     | [Link](https://www.ebay.com/itm/267006290535?_skw=proxmark+3)                                                                                 |

### Total Cost:

- With **Proxmark3 RDV4 Kit**: $461.21
- With **Flipper Zero**: $310.26
- With **Proxmark3 NFC RFID Card Reader Copier**: $179.21


### Software

- Python 3.x
- FastAPI
- Inky (Python library for ePaper display control)
- Uvicorn (ASGI server for FastAPI)
- Pillow (Python Imaging Library)

### Install Requirements

```bash
pip install fastapi uvicorn inky pillow
