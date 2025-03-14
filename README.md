# psychic paper an ePaper ID Badge Red team assessment tool.
![https://www.twitch.tv/zitterbewegung](https://img.shields.io/badge/Twitch-%239146FF.svg?style=for-the-badge&logo=Twitch&logoColor=white)

This project allows users to upload an image (JPEG format) through a FastAPI server and display it on an Inky ePaper display. It's designed to work with ID badges or other images that you want to render on a seven-color ePaper screen. The project supports automatic image orientation correction and resizing for the display resolution.

## Features

- **FastAPI-based Web Interface**: A simple web form to upload a JPEG image to be displayed on the ePaper screen.
- **ePaper Display Integration**: Uses the Inky Python library to render images on the Inky seven-color ePaper display.

## Requirements

### Hardware (Bill of Materials)

| Part Number | Description                                                                                       | Quantity | Supplier        | Unit Cost | Link                                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------- | -------- | --------------- | --------- |  --------------------------------------------------------------------------------------------------------------------------------------------- |
| 001         | Inky Impression 4" (7 colour ePaper/eInk HAT)                             | 1        | Pimoroni          | $72.99  | [Link](https://shop.pimoroni.com/products/inky-impression-4?variant=39599238807635)    | [Link]([https://www.amazon.com/Waveshare-4-01inch-Colorful-Display-640×400/dp/B0972R7F2Q](https://shop.pimoroni.com/products/inky-impression-4?variant=39599238807635))         
| 002         | Raspberry Pi Model 3a                                          | 1        | Amazon          | $34.99     | [Link](https://www.amazon.com/Raspberry-Pi-3-Computer-Board/dp/B07KKBCXLY)                                                               |
| 003 |    Leather Repair Tape Self-Adhesive Leather Repair Patch for Couch Furniture Sofas Car Seats Advanced PU Vinyl Leather Repair Kit (Dark Brown, 3.9X79 inch) | 1 | BSZHTECH (Amazon) | $7.99 | [Link](https://www.amazon.com/Leather-Repair-Self-Adhesive-Furniture-Advanced/dp/B09FDYKVMM/ref=asc_df_B09FDYKVMM?mcid=e7a05dfc072731c3965655695bde7f89&tag=hyprod-20&linkCode=df0&hvadid=693370761029&hvpos=&hvnetw=g&hvrand=18107484088857164679&hvpone=&hvptwo=&hvqmt=&hvdev=c&hvdvcmdl=&hvlocint=&hvlocphy=9021617&hvtargid=pla-1597570154544&th=1)
| 004 |   PNY 32GB Elite Class 10 U1 microSDHC Flash Memory Card  | 1 | PNY (Amazon) | $7.99 | [Link](https://www.amazon.com/PNY-Elite-microSDHC-Memory-P-SDU32GU185GW-GE/dp/B07R8GVGN9/)


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
```
Also install pimoroni for the raspberry pi.
```bash
curl https://get.pimoroni.com/inky | bash
```
### Rendering the case using openscad

docker run \
    -it \
    --rm \
    -v $(pwd):/openscad \
    -u $(id -u ${USER}):$(id -g ${USER}) \
    openscad/openscad:latest \
    openscad -o case.stl case.scad
