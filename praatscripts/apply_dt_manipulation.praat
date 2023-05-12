###########################################
# Apply DurationTier Manipulations
# Thomas Sostarics 08/13/2022
# Last updated: 08/13/2022
###########################################
# This script applies a duration tier
# from a given directory to its associated
# wav file in another directory. This is
# most useful if you've programmatically
# created duration tier manipulations in
# another software and now need to apply
# the manipulation to the audio file.
###########################################

form Apply DurationTier Manipulations
	comment Directory of sound files
	text fromDir ..\03_ChosenRecordings
	comment Directory of DurationTier files
	text dtDir ..\03_ChosenRecordings\DurationTiers
	comment Directory to save output files
	text outDir ..\04_ScaledRecordings
	comment Please enter the pitch range for the manipulation
	natural min 40
	natural max 200
endform


# Double check directory to make sure it ends in a slash
# Note: max and linux users might need to change \ to /
if right$(fromDir$, 1) <> "\"
	fromDir$ = fromDir$ + "\"
endif
if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif
if right$(dtDir$, 1) <> "\"
	dtDir$ = dtDir$ + "\"
endif

Create Strings as file list: "list", fromDir$ + "*.wav"
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	select Strings list
	filename$ = Get string: ifile
	
	Read from file: fromDir$ + filename$
	filename$ = left$(filename$, length(filename$)-4)
	Read from file: dtDir$ + filename$ + ".DurationTier"
	
	# Any spaces in the file name needs to be replaced
	# as underscores so praat can reference them in
	# the objects pane
	objname$ = replace$(filename$, " ", "_", 0)

	selectObject: "Sound " + objname$
	To Manipulation: 0.01, min, max
	
	selectObject: "DurationTier " + objname$
	plusObject: "Manipulation " + objname$
	Replace duration tier
	selectObject: "Manipulation " + objname$
	Get resynthesis (overlap-add)
	Save as WAV file: outDir$ + filename$ + ".wav"
endfor

select all
Remove
