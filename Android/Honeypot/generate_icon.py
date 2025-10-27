from PIL import Image, ImageDraw

# Create main icon (1024x1024 for launcher icon)
def create_honeypot_icon(size=1024):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    honey_color = (255, 187, 2, 255)  # #FFBB02
    pot_color = (139, 69, 19, 255)     # Braun
    honey_dark = (230, 150, 0, 255)
    
    # Draw honey pot
    center_x = size // 2
    pot_width = int(size * 0.7)
    pot_height = int(size * 0.65)
    pot_top = int(size * 0.25)
    
    # Pot body (trapezoid)
    pot_left = center_x - pot_width // 2
    pot_right = center_x + pot_width // 2
    pot_bottom = pot_top + pot_height
    
    pot_top_width = int(pot_width * 0.8)
    pot_top_left = center_x - pot_top_width // 2
    pot_top_right = center_x + pot_top_width // 2
    
    # Draw pot
    draw.polygon([
        (pot_top_left, pot_top),
        (pot_top_right, pot_top),
        (pot_right, pot_bottom),
        (pot_left, pot_bottom)
    ], fill=pot_color)
    
    # Draw honey inside pot
    honey_top = int(pot_top + pot_height * 0.15)
    honey_height = int(pot_height * 0.7)
    honey_left = int(pot_top_left + (pot_left - pot_top_left) * 0.15)
    honey_right = int(pot_top_right + (pot_right - pot_top_right) * 0.15)
    honey_bottom = honey_top + honey_height
    honey_left_bottom = int(pot_left + (pot_right - pot_left) * 0.1)
    honey_right_bottom = int(pot_right - (pot_right - pot_left) * 0.1)
    
    draw.polygon([
        (honey_left, honey_top),
        (honey_right, honey_top),
        (honey_right_bottom, honey_bottom),
        (honey_left_bottom, honey_bottom)
    ], fill=honey_color)
    
    # Draw honey drip
    drip_width = int(size * 0.08)
    drip_x = center_x + int(pot_width * 0.25)
    drip_y = honey_top - int(size * 0.05)
    draw.ellipse([
        drip_x - drip_width//2, drip_y - drip_width,
        drip_x + drip_width//2, drip_y + drip_width
    ], fill=honey_dark)
    
    # Draw pot rim
    rim_height = int(size * 0.04)
    draw.rectangle([
        pot_top_left - int(size * 0.02), pot_top - rim_height,
        pot_top_right + int(size * 0.02), pot_top
    ], fill=pot_color)
    
    return img

# Create foreground icon (for adaptive icon)
def create_foreground_icon(size=1024):
    return create_honeypot_icon(size)

# Generate icons
print("Generating honeypot icons...")
icon_main = create_honeypot_icon(1024)
icon_fg = create_foreground_icon(1024)

icon_main.save('assets/icon/honeypot_icon.png')
icon_fg.save('assets/icon/honeypot_icon_fg.png')
print("Icons generated successfully!")
print("Now run: flutter pub run flutter_launcher_icons")
