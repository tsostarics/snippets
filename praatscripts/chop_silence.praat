#####################################
# Chop End Silence
# Thomas Sostarics 09/09/2022
# Last updated: 09/09/2022
#####################################
# This script will extract the audio
# from a region that's some number of
# seconds before the first boundary
# on the given interval tier and
# some number of seconds after the
# last boundary on the same tier.
# For example, when your signal has
# 100 ms on the left and 230 on the right
# but you only want 30 milliseconds
# Note that this means you must be
# REDUCING the amount of silence.
#####################################

form Chop Silence
	comment Directory of sound files
	text fromDir ..\altest\input
	comment Directory of TextGrid files
	text tgFromDir ..\altest\input\TextGrids
	comment Directory to save output sound files
	text outDir ..\altest\output
	comment Directory to copy TextGrid files into
	text tgToDir ..\altest\output\TextGrids
	comment Number of seconds of silence (>0, 30ms = 0.03)
	positive leftSilence 0.03
	positive rightSilence 0.03
	comment Interval tier index to reference for timepoints
	integer tierNum 1
endform

# Double check directory to make sure it ends in a slash
# Note: max and linux users might need to change \ to /
if right$(fromDir$, 1) <> "\"
	fromDir$ = fromDir$ + "\"
endif
if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif
if right$(tgFromDir$, 1) <> "\"
	tgFromDir$ = tgFromDir$ + "\"
endif
if right$(tgToDir$, 1) <> "\"
	tgToDir$ = tgToDir$ + "\"
endif


# load files
Create Strings as file list: "list", fromDir$ + "*.wav"
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	select Strings list
	filename$ = Get string: ifile
	
	Read from file: fromDir$ + filename$
	filename$ = left$(filename$, length(filename$)-4)

	Read from file: tgFromDir$ + filename$ + ".TextGrid"
	# Any spaces in the file name needs to be replaced
	# as underscores so praat can reference them in
	# the objects pane
	objname$ = replace$(filename$, " ", "_", 0)
	
	# Get timepoints from interval tier
	selectObject: "TextGrid " + objname$
	startTime = Get end time of interval: tierNum, 1
	nIntervals = Get number of intervals: tierNum
	endTime = Get start time of interval: tierNum, nIntervals

	# Extract sound and save
	selectObject: "Sound " + objname$
	Extract part: startTime - leftSilence, endTime + rightSilence, "Rectangular", 1.0, "no"
	Save as WAV file: outDir$ + objname$ + ".wav"

	# Extract textgrid and save
	selectObject: "TextGrid " + objname$
	Extract part: startTime - leftSilence, endTime + rightSilence, "no"
	Save as text file: tgToDir$ + objname$ + ".TextGrid"

	# Remove files
	selectObject: "Sound " + objname$
	plusObject: "Sound " + objname$ + "_part"
	plusObject: "TextGrid " + objname$
	plusObject: "TextGrid " + objname$ + "_part"
	Remove
endfor

select all
Remove








