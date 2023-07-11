##########################################
#
# Generate Manipulations and Pitch Tiers
#
# Creates manipulations and pitch tier
# objects for each wav file in a directory
# Output file extensions are .Manipulation
# and .PitchTier.
#
# This is useful when you're first starting
# out with getting resynthesis files prepped
# 
##########################################

form Generate Manipulations and Pitch Tiers
	comment Directory of sound files
	text fromDir ..\02_PossibleRecordings
	comment Directory to save PitchTiers and Manipulations
	text outDir ..\02_PossibleRecordings\PitchTiers
	comment Should Manipulation files be saved? (0=No, 1=Yes)
	integer saveManipulations 0
	comment Should PitchTier and IntensityTier files be saved? (0=No, 1=Yes)
	integer savePitchTiers 1
	integer saveIntensityTiers 1
	comment Please enter the pitch range for the manipulation
	natural min 40
	natural max 200
endform

# Clean directories
fromDir$ = fromDir$ + "/"
outDir$ = outDir$ + "/"

Create Strings as file list: "list", fromDir$ + "*.wav"
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	select Strings list
	filename$ = Get string: ifile
	
	Read from file: fromDir$ + filename$
	filename$ = left$(filename$, length(filename$)-4)

	# Any spaces in the file name needs to be replaced
	# as underscores so praat can reference them in
	# the objects pane
	objname$ = replace$(filename$, " ", "_", 0)

	if saveIntensityTiers = 1
		selectObject: "Sound " + objname$
		To Intensity: min, 0, "no"
		Down to IntensityTier
		Save as text file: outDir$ + filename$ + ".IntensityTier"
		selectObject: "Intensity " + objname$
		plusObject: "IntensityTier " + objname$
		Remove
	endif
	
	selectObject: "Sound " + objname$
	To Manipulation: 0.01, min, max

	if saveManipulations = 1
		selectObject: "Manipulation "+ objname$
		Save as binary file: outDir$ + filename$ + ".Manipulation"
	endif

	if savePitchTiers = 1
		selectObject: "Manipulation " + objname$
		Extract pitch tier
		Save as text file: outDir$ + filename$ + ".PitchTier"
		selectObject: "PitchTier " + objname$
		Remove
	endif
	selectObject: "Manipulation " + objname$
	plusObject: "Sound " + objname$
	Remove
endfor

select all
Remove