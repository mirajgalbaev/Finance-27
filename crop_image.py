from PIL import Image
import os

img_path = "assets/app_icon.jpg"
if not os.path.exists(img_path):
    print("Image not found!")
    exit(1)

img = Image.open(img_path)
width, height = img.size

# Assuming it's a 1024x1024 image or similar square.
# The text is usually at the bottom 20-25% of the image.
# We will crop out the bottom text.
# Let's crop it to a square focusing on the center-top.
# Bounding box: (left, upper, right, lower)
# Let's crop a square from the top to avoid the text, or just crop the text off making it a rectangle,
# but splash screens usually expect a square logo. 
# A centered crop of the top 75% maybe?

# Let's just crop out the text. The circular logo is centered.
# We can make a crop of size (width, height * 0.8) and then maybe add padding or just keep it as is.
# Actually, the user asked for the image without the text.
crop_box = (0, 0, width, int(height * 0.82))
cropped_img = img.crop(crop_box)

# Now let's make it square again by padding with the background color (dark blue).
# We can sample the top-left pixel for the background color.
bg_color = img.getpixel((0, 0))

# Create new square image
new_size = max(width, int(height * 0.82))
square_img = Image.new('RGB', (width, width), bg_color)

# Paste the cropped image into the center
paste_y = (width - int(height * 0.82)) // 2
square_img.paste(cropped_img, (0, paste_y))

# Save for splash
square_img.save("assets/splash_icon.png")
print("Cropped successfully!")

