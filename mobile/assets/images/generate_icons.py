#!/usr/bin/env python3
"""Generate InkaWallet app icons and splash screen"""

from PIL import Image, ImageDraw, ImageFont
import os

# Colors
PRIMARY_BLUE = (30, 136, 229)  # #1E88E5
WHITE = (255, 255, 255)
DARK_GRAY = (66, 66, 66)

def create_app_icon(size=1024):
    """Create main app icon with gradient background and IW text"""
    # Create image with blue background
    img = Image.new('RGB', (size, size), PRIMARY_BLUE)
    draw = ImageDraw.Draw(img)
    
    # Try to load a font, fallback to default
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size//3)
    except:
        font = ImageFont.load_default()
    
    # Draw "IW" text in white
    text = "IW"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    position = ((size - text_width) // 2, (size - text_height) // 2 - 50)
    draw.text(position, text, fill=WHITE, font=font)
    
    # Add rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=size//8, fill=255)
    
    output = Image.new('RGB', (size, size), PRIMARY_BLUE)
    output.paste(img, (0, 0))
    
    return output

def create_app_icon_foreground(size=1024):
    """Create adaptive icon foreground (transparent with logo)"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size//3)
    except:
        font = ImageFont.load_default()
    
    # Draw "IW" in white
    text = "IW"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    position = ((size - text_width) // 2, (size - text_height) // 2)
    draw.text(position, text, fill=WHITE, font=font)
    
    return img

def create_splash_logo(size=512):
    """Create splash screen logo"""
    img = Image.new('RGBA', (size * 2, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    try:
        title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size//4)
        subtitle_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size//10)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # Draw "InkaWallet" title
    title = "InkaWallet"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    title_height = bbox[3] - bbox[1]
    
    title_pos = ((size * 2 - title_width) // 2, size // 3)
    draw.text(title_pos, title, fill=PRIMARY_BLUE, font=title_font)
    
    # Draw subtitle
    subtitle = "Accessible Banking for Everyone"
    bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = bbox[2] - bbox[0]
    
    subtitle_pos = ((size * 2 - subtitle_width) // 2, size // 3 + title_height + 20)
    draw.text(subtitle_pos, subtitle, fill=DARK_GRAY, font=subtitle_font)
    
    return img

def main():
    output_dir = os.path.dirname(__file__)
    
    print("Generating InkaWallet app icons...")
    
    # Generate app icon
    print("Creating app_icon.png (1024x1024)...")
    app_icon = create_app_icon(1024)
    app_icon.save(os.path.join(output_dir, 'app_icon.png'))
    
    # Generate adaptive icon foreground
    print("Creating app_icon_foreground.png (1024x1024)...")
    foreground = create_app_icon_foreground(1024)
    foreground.save(os.path.join(output_dir, 'app_icon_foreground.png'))
    
    # Generate splash logo
    print("Creating splash_logo.png (1024x512)...")
    splash = create_splash_logo(512)
    splash.save(os.path.join(output_dir, 'splash_logo.png'))
    
    print("\n✅ Icons generated successfully!")
    print("\nNext steps:")
    print("1. cd mobile")
    print("2. flutter pub get")
    print("3. flutter pub run flutter_launcher_icons")
    print("4. flutter pub run flutter_native_splash:create")

if __name__ == '__main__':
    main()
