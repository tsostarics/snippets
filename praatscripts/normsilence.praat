#####################################
# Normalize Silence Length
# Thomas Sostarics 1/26/2021
# 
# Given a directory of .wav files
# with corresponding text grids
# with 1 interval tier, where
# 1 interval is labeled 'sil' (silence)
# make this interval equal to the given 
# value. You will need to create a 
# Sound object titled 'silence' 
# containing enough ambient noise at
# the same level as the recordings in
# your directory so that the script
# can copy from it and splice it into
# files with short intervals.
#
# This was designed to be used after
# my Segment Silence by Intensity script.
# You can also use that script on
# the output of this script & compare
# the change in durations of the interval.
#
#####################################
form Normalize Silence Length
	comment Directory of input sound files
	text fromDir C:\
	comment Directory of output text grids
	text outDir C:\
	comment Desired Silence length (s)
	natural toLen 1.0
	comment Tolerance (s)
	natural .008
endform

# Double check directory to make sure it ends in a slash
# Note: max and linux users might need to change \ to /
if right$(fromDir$, 1) <> "\"
	fromDir$ = fromDir$ + "\"
endif
if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif
writeInfoLine: fromDir$
Create Strings as file list: "list", fromDir$ + "*.wav"
numberOfFiles = Get number of strings
selectObject: "Sound silence"
View & Edit

for ifile to numberOfFiles
	## Load files
	select Strings list
	filename$ = Get string: ifile
	Read from file: fromDir$ + filename$
	objname$ = left$(filename$, length(filename$)-4)
	Read from file: fromDir$ + objname$ + ".TextGrid"

	## Get info about the silence interval
	selectObject: "TextGrid " + objname$
	len = Get total duration of intervals where: 1, "is equal to", "sil"
	startTime = Get start time of interval: 1, 2
	endTime = Get end time of interval: 1, 2
	midpoint = (startTime + endTime)/2

	## Cut out silence if needed
	if len > (toLen + tolerance)
		cut = (len - toLen)/2
		selectObject: "Sound " + objname$
		View & Edit
		editor: "Sound " + objname$
		Move cursor to: midpoint
		Move cursor to nearest zero crossing
		Select: midpoint-cut, midpoint+cut
		Move start of selection to nearest zero crossing
		Move end of selection to nearest zero crossing
		editor: "Sound " + objname$
		Cut
		endeditor
	## Or add in silence if needed
	elsif len < (toLen - tolerance)
		cut = toLen - len
		editor: "Sound silence"
		Select: 0.009, cut
		Move start of selection to nearest zero crossing
		Move end of selection to nearest zero crossing
		selectObject: "Sound silence"
		Copy selection to Sound clipboard
		endeditor
		selectObject: "Sound " + objname$
		View & Edit
		editor: "Sound " + objname$
		Move cursor to: midpoint
		Move cursor to nearest zero crossing
		Paste after selection
		endeditor
	endif

	selectObject: "Sound " + objname$
	Save as WAV file: outDir$ + objname$ + ".wav"
	selectObject: "Sound " + objname$
	plusObject: "TextGrid " + objname$
	Remove
endfor

