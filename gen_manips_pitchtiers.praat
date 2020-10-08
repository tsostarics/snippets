##########################################
#
# Generate Manipulations and Pitch Tiers
#
# Creates manipulations and pitch tier
# objects for each wav file in a directory
# Output file extensions are .Manipulation
# and .PitchTier. See related python script
# for processing .PitchTier files for 
# spaghetti plots
#
# This is useful when you're first starting
# out with getting resynthesis files prepped
# 
##########################################

outDir$ = "C:\Users\tsost\Desktop\flat contours\"
echo 'outDir$'
strings = Create Strings as file list: "fileList", outDir$ + "*.wav"
numberOfFiles = Get number of strings
for ifile to numberOfFiles
	selectObject: strings
	filename$ = Get string: ifile
	printline: filename$
	Read from file: outDir$ + filename$

	filename$ = left$(filename$, length(filename$)-4)
	echo 'filename$'

	selectObject: "Sound " + filename$
	To Manipulation: 0.01, 25, 350

	selectObject: "Manipulation "+ filename$
	Save as binary file: outDir$ + filename$ + ".Manipulation"

	selectObject: "Manipulation "+ filename$
	Extract pitch tier
	Save as text file: outDir$ + filename$ + ".PitchTier"
endfor

select all
Remove