#!/usr/bin/env python3
from sys import argv
import os
from PIL import Image

path = str(argv[1])
dest_path = str(argv[2])
if not os.path.exists(dest_path):
    os.makedirs(dest_path)

box = (int(argv[3]), int(argv[4]), int(argv[5]), int(argv[6]))

for f in os.listdir(path):
    img_path = os.path.join(path,f)
    with Image.open(img_path) as img:
        cropped_img = img.crop(box)
        cropped_img.save(os.path.join(dest_path, f))

