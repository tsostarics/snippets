#####################################
# Quick Extract
# Thomas Sostarics 2/11/2021
#
# For each file in the directory, 
# opens an editor window so you can 
# select a desired window, then saves
# the file in the given directory
#
#####################################

form Split at
	comment Directory of input sound files
	text fromDir C:\Users\tsost\Box\Research\QP\Recordings\8 Split Dialogues\normalized
	comment Directory of output split sound files
	text outDir C:\Users\tsost\Box\Research\QP\Recordings\8 Split Dialogues\final
endform

# Double check directory to make sure it ends in a slash
# Note: max and linux users might need to change \ to /
if right$(fromDir$, 1) <> "\"
	fromDir$ = fromDir$ + "\"
endif
if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif

Create Strings as file list: "list", fromDir$ + "*.wav"
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	# Set object and variable info
	select Strings list
	filename$ = Get string: ifile
	Read from file: fromDir$ + filename$
	objname$ = left$(filename$, length(filename$)-4)
	selectObject: "Sound " + objname$
	View & Edit
	beginPause: "Press continue after making selection"
	endPause: "Continue", 1

	# Open editor to select window to extract
	editor: "Sound " + objname$
  	Move end of selection to nearest zero crossing
	Move start of selection to nearest zero crossing
	Extract selected sound (windowed): objname$ + "_short", "rectangular", 1, "no"
	endeditor

	# Save audio file and remove objects
	selectObject: "Sound " + objname$ + "_short"
	Save as WAV file: outDir$ + objname$ + ".wav"
	selectObject: "Sound " + objname$ + "_short"
	plusObject: "Sound " + objname$
	Remove
endfor
selectObject: "Strings list"
Remove