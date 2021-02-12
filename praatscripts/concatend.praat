#####################################
# Quick concatenate
#
# For each file in the directory, 
# concatenates silence to the end
# of each file. (must have an object
# named "Sound silence" in your
# objects pane)
#
#####################################

form Quick concatenate
	comment integer ID of the silence object
	integer sID 459
	comment Directory of input sound files
	text fromDir C:\Users\tsost\Box\Research\QP\Recordings\8 Split Dialogues
	comment Directory of output split sound files
	text outDir C:\Users\tsost\Box\Research\QP\Recordings\8 Split Dialogues\normalized
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
	
	selectObject: "Sound silence"
	Copy: "silence"

	# Concatenate and save file
	selectObject: "Sound " + objname$
	plusObject: "Sound silence"
	Concatenate
	selectObject: "Sound chain"
	Save as WAV file: outDir$ + objname$ + ".wav"
	
	# Clean up objects
	selectObject: "Sound chain"
	plusObject: "Sound " + objname$
	plusObject: "Sound silence"
	Remove
endfor
selectObject: "Strings list"
Remove