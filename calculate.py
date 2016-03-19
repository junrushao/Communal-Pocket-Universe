
sum = 0
with open("data.hex", "r") as infile:
	for line in infile.readlines()[:100]:
		sum += int(line, 16)
	print sum

