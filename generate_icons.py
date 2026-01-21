"""
Generate high-quality Windows app icons from a source image.
Requires: pip install Pillow
"""
import sys
try:
    from PIL import Image, ImageFilter
except ImportError:
    print("Installing Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageFilter

def high_quality_resize(img, size):
    """
    High quality resize with anti-aliasing for small icons.
    """
    # For small sizes, use a multi-step resize for better quality
    if size[0] < 64:
        # First resize to 2x target, then to target
        intermediate_size = (size[0] * 4, size[1] * 4)
        img_temp = img.resize(intermediate_size, Image.Resampling.LANCZOS)
        # Apply slight sharpening to compensate for blur
        img_temp = img_temp.filter(ImageFilter.UnsharpMask(radius=1, percent=50, threshold=3))
        return img_temp.resize(size, Image.Resampling.LANCZOS)
    else:
        return img.resize(size, Image.Resampling.LANCZOS)

def generate_icons(source_path):
    # Open source image
    img = Image.open(source_path)
    
    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Ensure source is high resolution - resize up if needed
    if img.width < 512 or img.height < 512:
        # Scale up to 512x512 first for better downscaling
        img = img.resize((512, 512), Image.Resampling.LANCZOS)
    
    # Windows ICO sizes - include more sizes for better quality at different DPIs
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    
    # Generate ICO for Windows app
    ico_images = []
    for size in ico_sizes:
        resized = high_quality_resize(img, size)
        ico_images.append(resized)
    
    # Save as ICO (largest first for better compatibility)
    ico_images_reversed = list(reversed(ico_images))
    
    ico_path = 'windows/runner/resources/app_icon.ico'
    ico_images_reversed[0].save(
        ico_path,
        format='ICO',
        sizes=[(s[0], s[1]) for s in reversed(ico_sizes)],
        append_images=ico_images_reversed[1:]
    )
    print(f"Generated: {ico_path}")
    
    # Also save to assets for system tray
    assets_ico_path = 'assets/app_icon.ico'
    ico_images_reversed[0].save(
        assets_ico_path,
        format='ICO',
        sizes=[(s[0], s[1]) for s in reversed(ico_sizes)],
        append_images=ico_images_reversed[1:]
    )
    print(f"Generated: {assets_ico_path}")
    
    # Generate PNG for other uses
    img_256 = high_quality_resize(img, (256, 256))
    img_256.save('assets/app_icon.png', format='PNG')
    print("Generated: assets/app_icon.png")
    
    print("\nDone! High-quality icons generated successfully.")
    print(f"Sizes included: {[f'{s[0]}x{s[1]}' for s in ico_sizes]}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generate_icons.py <source_image>")
        print("Example: python generate_icons.py icon.png")
        sys.exit(1)
    
    generate_icons(sys.argv[1])
