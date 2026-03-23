from PIL import Image, ImageDraw
import os

# Create 1024x1024 icon
size = 1024
img = Image.new('RGBA', (size, size), (0, 132, 255, 255))
draw = ImageDraw.Draw(img)

# Draw chat bubble
bubble_x1 = size * 0.2
bubble_y1 = size * 0.2
bubble_x2 = size * 0.8
bubble_y2 = size * 0.7
radius = 80

draw.rounded_rectangle([bubble_x1, bubble_y1, bubble_x2, bubble_y2],
                       radius=radius, fill='white')

# Tail
draw.polygon([
    (bubble_x1 + 80, bubble_y2),
    (bubble_x1 + 80, bubble_y2 + 120),
    (bubble_x1 + 200, bubble_y2),
], fill='white')

# N letter
draw.text((size//2 - 60, size//2 - 80), 'N', fill=(0, 132, 255, 255))

img.save('icon.png')
print('Icon created!')
