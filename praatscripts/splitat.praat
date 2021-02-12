#####################################
# Split at a location in the audio
# Thomas Sostarics 2/11/2021
#
# For each file in the directory, 
# opens an editor window so you can 
# click where you want to split at
# then saves the two new files while
# concatenating silence to both ends.
# You should use the quickextract
# script on the files afterwards
# so you can control the amount of 
# silence you want on the ends.
#
#####################################
form Split at
	comment Directory of input sound files
	text fromDir 
	comment Directory of output split sound files
	text outDir 
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
previousWord$ = ""

for ifile to numberOfFiles
	# Set object and variable info
	select Strings list
	filename$ = Get string: ifile
	Read from file: fromDir$ + filename$
	objname$ = left$(filename$, length(filename$)-4)
	# note: the project i wrote this for had some extra stuff at the end of the file name i needed to chop off here
	currentWord$ = left$(objname$, length(objname$)-4)
	selectObject: "Sound " + objname$
	View & Edit
	beginPause: "Press continue after making selection"
	endPause: "Continue", 1
	splitLocation= 0
	endFile = 100
	
	# Open editor to select split location and extract audio portions
	editor: "Sound " + objname$
  	Move cursor to nearest zero crossing
	splitLocation = Get cursor
	Move cursor to: 100
	endFile = Get cursor
	Select: splitLocation, endFile
	Move end of selection to nearest zero crossing
	Extract selected sound (windowed): objname$ + "_resp", "rectangular", 1, "no"
	Select: 0, splitLocation
	Move start of selection to nearest zero crossing
	Extract selected sound (windowed): objname$ + "_pre", "rectangular", 1, "no"
	endeditor
	
	# Copy silence so we can concatenate on both ends	
	selectObject: "Sound silence"
	Copy: "silence2"

	# Concatenate and save response
	selectObject: "Sound silence"
	plusObject: "Sound " + objname$ + "_resp"
	plusObject: "Sound silence2"
	Concatenate
	selectObject: "Sound chain"
	Save as WAV file: outDir$ + objname$ + ".wav"
	selectObject: "Sound chain"
	Remove
	
	# Concatenate and save preamble if we don't have one yet
	selectObject: "Sound silence"
	plusObject: "Sound " + objname$ + "_pre"
	plusObject: "Sound silence2"
	Concatenate
	if currentWord$ <> previousWord$
		selectObject: "Sound chain"
		Save as WAV file: outDir$ + currentWord$ + "_pre.wav"
		previousWord$ = currentWord$
	endif		
	
	# Clean up objects created in this loop
	selectObject: "Sound chain"
	plusObject: "Sound silence2"
	plusObject: "Sound " + objname$
	plusObject: "Sound " + objname$ + "_pre"
	plusObject: "Sound " + objname$ + "_resp"
	Remove
	endif
endfor
selectObject: "Strings list"
Remove


