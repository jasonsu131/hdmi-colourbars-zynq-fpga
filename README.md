# HDMI Color Bar Generator (640×480 @ 60Hz) on FPGA

This project implements a simple HDMI (DVI-D compatible) video output on a Xilinx FPGA using Verilog.  
It generates 640×480 @ 60 Hz color bars and outputs them through the HDMI port.

The design uses a pixel clock derived from a 100 MHz system clock and the Xilinx `rgb2dvi` IP core for TMDS encoding.

---

## Features

- 640×480 @ 60 Hz video timing (VGA standard)
- 8 vertical color bars
- HDMI/DVI-D compatible output
- Pure Verilog top-level design
- External TMDS serialization using a 5× pixel clock
- Works with standard HDMI monitors
- TMDS Reset button

![IMG_9714](https://github.com/user-attachments/assets/24dee3f8-b081-49c9-bf3b-374ee7d2372a)
