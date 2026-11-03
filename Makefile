# Files in the project. Make sure the first file is the top module
VHD = main.vhd rotary_encoder/Encoder.vhd rotary_encoder/Debouncer.vhd Mem/uMem.vhd Mem/pMem.vhd Lookup/K1.vhd \
Lookup/K2.vhd cpu/uprogCPU.vhd vga_motor/celestial_pkg.vhd vga_motor/seagull_pkg.vhd vga_motor/seagull.vhd vga_motor/celestial_body.vhd \
vga_motor/bird_pkg.vhd vga_motor/bird_sprite.vhd vga_motor/video_ram.vhd \
vga_motor/vga_motor.vhd vga_motor/tile_rom.vhd

# Design constraints file
XDC = Basys3.xdc

# Testbench file
TBF = cpu/uprogCPU_tb.vhd

# Include Makefile utilities
include /courses/TSEA83/bin/util.mk



