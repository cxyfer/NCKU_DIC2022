import re

encodeData = './img0/testdata_encoder.dat'
decodeData = './img0/testdata_decoder.dat'

def openData(file):
	with open(file, 'r', encoding="utf-8") as data:
		List = [ line.strip() for line in data ]
	return List

goldenEncodeList = openData(encodeData)
goldenDecodeList = openData(decodeData)

targetString = goldenEncodeList[0][7:]
#targetString = '112a112a2112112112a21$'
goldenEncodeData = goldenEncodeList[1:]
searchWindowSize = 9
previewWindowSize = 8
maxMatchLen = 7

def LCS(str1, str2, maxMatchLen=7):
	maxL = 0
	offset = 0
	for i in range(len(str1)):
		longest = 0
		for j in range(len(str2)):
			if (str1+str2)[i+j] == str2[j] and longest < maxMatchLen:
				longest += 1
				if (longest > maxL):
					maxL = longest
					offset = len(str1)-1-i
			else:
				break
	return maxL, offset

def Encode(text, searchWindowSize, previewWindowSize):
	result = []
	i = 0
	while (i < len(text)):
		previewString = text[i:i+previewWindowSize]
		searchWindowOffset = 0
		searchWindowOffset = i if (i < searchWindowSize) else searchWindowSize
		searchString = text[i - searchWindowOffset:i]
		matchLen, offset = LCS(searchString, previewString, maxMatchLen)
		nextChar = ''
		if (matchLen == len(previewString)): #
			nextChar = '' if (i + matchLen == len(text)) else text[i+previewWindowSize]
		else:
			nextChar = previewString[matchLen]
			if (matchLen == 0):
				cur = [0, 0, nextChar]
			else:
				cur = [offset, matchLen, nextChar]
			#print(cur)
			result.append(cur)
		i = i + matchLen + 1
	return result
def Decode(enRes, searchWindowSize):
	decodeResult = []
	decodeString = ''
	searchString = ''
	for i in range(len(enRes)):
		offset, matchLen, nextChar = enRes[i]
		if (matchLen==0):
			curRes = nextChar
		else:
			pos = len(searchString)-1-offset
			if (pos + matchLen) > len(searchString):
				overlay = searchString[pos: pos+matchLen] # Overlay
				curRes = (overlay+overlay+overlay+overlay)[:matchLen] + nextChar
			else:
				curRes = searchString[pos: pos+matchLen] + nextChar
		decodeString += curRes
		searchString += curRes
		if len(searchString) > searchWindowSize:
			searchString = searchString[len(searchString) - searchWindowSize:]
		decodeResult.append(curRes)
	return decodeResult, decodeString

'''for j in range(7, 1, -1):
	for i in range(16, 7, -1):
		List = [f"buffer[{7-k}] == buffer[{i-k}]" for k in range(j)]
		print("if ({})".format(" && ".join(List)))
	print()'''

L = [f"buffer[{j}]" for j in range(7, 1, -1)]
print(",".join(L))
for i in range(16, 7, -1):
	List = [f"buffer[{i-k}]" for k in range(i)]
	print(",".join(List))
exit()

# Encode
print(f'targetString: {targetString}')
result = Encode(targetString, searchWindowSize, previewWindowSize)
## Test
check = False if len(result) != len(goldenEncodeData) else True
for i in range(len(result)):
	res = f'encode:{result[i][0]}:{result[i][1]}:{result[i][2]}'
	if (res != goldenEncodeData[i]):
		print(f'{i}: {res} {goldenEncodeData[i]}')
		check = False
	#print(res, goldenEncodeData[i], res == goldenEncodeData[i])
if not check:
	print(f'resultLen: {len(result)} goldenLen: {len(goldenEncodeData)}')
else:
	print('Answer is Right.')

# Decode
deRes, deStr = Decode(result, searchWindowSize)
for i in range(len(deRes)):

	res = f'decode:{result[i][0]}:{result[i][1]}:{result[i][2]}:{deRes[i]}'
	if (res != goldenDecodeList[i]):
		print(f'{i}: {res} {goldenDecodeList[i]}')
		check = False
	#print(res, goldenDecodeList[i], res == goldenDecodeList[i])