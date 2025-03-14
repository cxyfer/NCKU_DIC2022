import cv2
import numpy as np
import os
import sys

imagepath = './image.jpg' if len(sys.argv) <= 2 else sys.argv[-1]
print(f"Image: {imagepath}")
goldenpath = './output/golden.dat'
outputpath = './output/img.dat'

if not os.path.isdir('./output'):
	os.mkdir('./output')

img = cv2.imread(imagepath)
img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
img_resize = cv2.resize(img_gray, (32, 31))

for i in range(31):
	if i%2 == 0: continue
	for j in range(32):
		af = abs(int(img_resize[i-1][j-1]) - int(img_resize[i+1][j+1])) if (j>0 and j<31) else 255
		be = abs(int(img_resize[i-1][j])   - int(img_resize[i+1][j]))
		cd = abs(int(img_resize[i-1][j+1]) - int(img_resize[i+1][j-1])) if (j>0 and j<31) else 255
		if min(af, be, cd) == be:
			img_resize[i][j] = int( (int(img_resize[i-1][j]) + int(img_resize[i+1][j]))/2 )
		elif min(af, be, cd) == af:
			img_resize[i][j] = int( (int(img_resize[i-1][j-1]) + int(img_resize[i+1][j+1]))/2 )
		else:
			img_resize[i][j] = int( (int(img_resize[i-1][j+1]) + int(img_resize[i+1][j-1]))/2 )

with open(goldenpath, "w") as data:
	for i in range(31):
		for j in range(32):
			text = hex(int(img_resize[i][j])).replace("0x", "")
			data.write(f"{text}\n")
        
with open(outputpath, "w") as data:
	for i in range(31):
		if i%2 == 1: continue
		for j in range(32):
			text = hex(int(img_resize[i][j])).replace("0x", "")
			data.write(f"{text}\n")

