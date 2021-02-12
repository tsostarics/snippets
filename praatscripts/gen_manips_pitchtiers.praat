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

form Generate Manipulations and Pitch Tiers
	comment Directory of sound files
	text outDir C:\Users\temp\
	comment Please enter the pitch range for the manipulation
	natural min 50
	natural max 350
endform

if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif

strings = Create Strings as file list: "fileList", outDir$ + "*.wav"
numberOfFiles = Get number of strings
for ifile to numberOfFiles
	selectObject: strings
	filename$ = Get string: ifile
	
	Read from file: outDir$ + filename$
	filename$ = left$(filename$, length(filename$)-4)

	# Any spaces in the file name needs to be replaced
	# as underscores so praat can reference them in
	# the objects pane
	objname$ = replace$(filename$, " ", "_", 0)

	selectObject: "Sound " + objname$
	To Manipulation: 0.01, min, max

	selectObject: "Manipulation "+ objname$
	Save as binary file: outDir$ + filename$ + ".Manipulation"

	selectObject: "Manipulation "+ objname$
	Extract pitch tier
	Save as text file: outDir$ + filename$ + ".PitchTier"
endfor

select all
Remove