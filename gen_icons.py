from PIL import Image
import os

root = os.path.dirname(os.path.abspath(__file__))
icon_dir = os.path.join(root, 'LaReserva', 'Assets.xcassets', 'AppIcon.appiconset')

# Use the Android xxxhdpi icon (192x192) as the source - it's the real app icon
src = os.path.join(root, '..', 'drogueria_la_reserva_app', 'android', 'app', 'src', 'main', 'res', 'mipmap-xxxhdpi', 'ic_launcher.png')
print(f'Source: {src}')
img = Image.open(src)
print(f'Size: {img.size} mode={img.mode}')

# Create a solid white background of the same size to strip alpha/transparency (iOS requirement)
background = Image.new('RGBA', img.size, (255, 255, 255, 255))
background.paste(img, (0, 0), img if img.mode == 'RGBA' else None)
final = background.convert('RGB')

entries = [
    ('20', '2x', 40),
    ('20', '3x', 60),
    ('29', '2x', 58),
    ('29', '3x', 87),
    ('40', '2x', 80),
    ('40', '3x', 120),
    ('60', '2x', 120),
    ('60', '3x', 180),
    ('20', '1x', 20),
    ('29', '1x', 29),
    ('40', '1x', 40),
    ('76', '1x', 76),
    ('76', '2x', 152),
    ('83.5', '2x', 167),
    ('1024', '1x', 1024),
]

for size, scale, px in entries:
    sz_name = size.replace('.', '_')
    fname = f'icon_{sz_name}_{scale}.png'
    fpath = os.path.join(icon_dir, fname)
    resized = final.resize((px, px), Image.Resampling.LANCZOS)
    resized.save(fpath, 'PNG')
    print(f'  {fname} ({px}x{px})')

print('Done - icons generated from Android ic_launcher')
