from PIL import Image

# ===== CONFIG =====
INPUT_FILE = "måsfisk.png" 
FRAME_WIDTH = 32
FRAME_HEIGHT = 32
NUM_FRAMES = 2
OUTPUT_FILE = "måsfisk_pkg.vhd"
# ==================

img = Image.open(INPUT_FILE).convert("RGBA")
# Vi antar att frames ligger horisontellt i bilden
# Om din bild är 128x16 pixlar (8 frames * 16 bred)

frames_data = []

for f in range(NUM_FRAMES):
    frame_pixels = []
    # Start-X för denna frame
    start_x = f * FRAME_WIDTH
    
    for y in range(FRAME_HEIGHT):
        for x in range(start_x, start_x + FRAME_WIDTH):
            r, g, b, a = img.getpixel((x, y))

            # KOLLA TRANSPARENS
            if a < 128:
                color = 0xF0F # Magenta
            else:
                # RGB888 -> RGB444
                r4 = r >> 4
                g4 = g >> 4
                b4 = b >> 4
                color = (r4 << 8) | (g4 << 4) | b4
            
            frame_pixels.append(color)
    frames_data.append(frame_pixels)

# ===== GENERERA VHDL OUTPUT =====
with open(OUTPUT_FILE, "w") as f:
    f.write("    constant SPRITE_MEM : sprite_array := (\n")
    
    for f_idx, frame in enumerate(frames_data):
        f.write(f"\n        -- Frame {f_idx}\n")
        for row_idx in range(FRAME_HEIGHT):
            # Plocka ut 16 pixlar för en rad
            row = frame[row_idx * FRAME_WIDTH : (row_idx + 1) * FRAME_WIDTH]
            row_str = ",".join([f'x"{c:03X}"' for c in row])
            
            # Kommatecken efter alla rader utom absolut sista i sista framen
            if f_idx == NUM_FRAMES - 1 and row_idx == FRAME_HEIGHT - 1:
                f.write(f"        {row_str}\n")
            else:
                f.write(f"        {row_str},\n")
                
    f.write("\n    );")

print(f"KLAR! Data för {NUM_FRAMES} frames sparad i {OUTPUT_FILE} 🚀")