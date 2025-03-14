import cv2
from PIL import Image
import numpy as np
import os
import sys


if __name__ == "__main__":
	width = 128
	height = 63

	for index in range(3):
		imagepath = './img' + str(index) + '/test_img.png'
		goldenpath = f'./img{index}/out_golden.dat'
		outputpath = f'./img{index}/out_image.dat'

		img = Image.open(imagepath)
		img_gray = img.convert('L')
		img_gray = np.array(img_gray)
		#img = cv2.imread(imagepath)
		#img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
		img_resize = img_gray

		for i in range(height):
			if i%2 == 0: continue
			for j in range(width):
				af = abs(int(img_resize[i-1][j-1]) - int(img_resize[i+1][j+1])) if (j>0 and j<width-1) else 255
				be = abs(int(img_resize[i-1][j])   - int(img_resize[i+1][j]))
				cd = abs(int(img_resize[i-1][j+1]) - int(img_resize[i+1][j-1])) if (j>0 and j<width-1) else 255
				if min(af, be, cd) == be:
					img_resize[i][j] = int( (int(img_resize[i-1][j]) + int(img_resize[i+1][j]))/2 )
				elif min(af, be, cd) == af:
					img_resize[i][j] = int( (int(img_resize[i-1][j-1]) + int(img_resize[i+1][j+1]))/2 )
				else:
					img_resize[i][j] = int( (int(img_resize[i-1][j+1]) + int(img_resize[i+1][j-1]))/2 )

		with open(goldenpath, "w") as data:
			for i in range(height):
				for j in range(width):
					text = hex(int(img_resize[i][j])).replace("0x", "")
					data.write(f"{text}\n")
		
		with open(outputpath, "w") as data:
			for i in range(height):
				if i%2 == 1: continue
				for j in range(width):
					text = hex(int(img_resize[i][j])).replace("0x", "")
					data.write(f"{text}\n")

