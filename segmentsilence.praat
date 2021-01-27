#####################################
# Segment Silence by Intensity
# Thomas Sostarics 1/26/2021
# 
# This script is used when you want
# to measure the duration of silence
# in only one part of a file (say,
# the silence between two particular
# turns of conversation). This will
# open up each wav file in a directory
# in turn, and you just need to highlight
# some region within the silence. Doesn't
# need to be exact, but try to catch
# any noticeable bumps in the waveform.
# After selecting the region, press the
# Continue button on the small popup
# window to move to the next file.
# The script will then move outwards
# until it finds an intensity listing
# higher than the given threshold.
# Textgrids saved in the designated folder.
#
#####################################
form Segment Turns
	comment Directory of input sound files
	text fromDir C:\
	comment Directory of output text grids
	text outDir C:\
	comment Threshold (in dB)
	integer threshold 62
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
	select Strings list
	filename$ = Get string: ifile
	Read from file: fromDir$ + filename$
	objname$ = left$(filename$, length(filename$)-4)
	selectObject: "Sound " + objname$
 	To TextGrid: "turn", ""
 	selectObject: "Sound " + objname$
  	View & Edit
  	beginPause: "Press continue after making selection"
  	endPause: "Continue", 1
  editor: "Sound " + objname$
  	Zoom to selection
  	Zoom out
  	Zoom out
  	meanIntensity = Get intensity
	## Modify these two lines if you need to specify the threshold differently
  	endThreshold = threshold
  	startThreshold = threshold
  	maxIntNow = meanIntensity
  	## Crawl right
  	while maxIntNow < endThreshold
  		Move end of selection by: 0.05
  		maxIntNow = Get maximum intensity
  	endwhile
  	while maxIntNow > endThreshold
  		Move end of selection by: -0.008
  		endTime = Get end of selection
  		maxIntNow = Get maximum intensity
  	endwhile
  	Move end of selection to nearest zero crossing
  	endTime = Get end of selection
  	Move end of selection by: -0.05
  	maxIntNow = meanIntensity
  	## Crawl left
  	while maxIntNow < startThreshold
  		Move start of selection by: -0.05
  		maxIntNow = Get maximum intensity
  	endwhile
  	while maxIntNow > startThreshold
  		Move start of selection by: 0.008
  		startTime = Get start of selection
  		maxIntNow = Get maximum intensity
  	endwhile
  	Move start of selection to nearest zero crossing
  	startTime = Get start of selection
  	writeInfoLine: startTime, " ", endTime
  endeditor
  
  selectObject: "Sound " + objname$
  plusObject: "TextGrid " + objname$
  Edit
  editor: "TextGrid " + objname$
  	Select: startTime, endTime
  	Add on tier 1
  endeditor
  selectObject: "TextGrid " + objname$
  Set interval text: 1, 2, "sil"
  Save as text file: outDir$ + objname$ + ".TextGrid"
  selectObject: "Sound "+ objname$
  plusObject: "TextGrid " + objname$
  Remove
endfor