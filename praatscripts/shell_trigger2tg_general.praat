################################################################################
# Triggers to TextGrids (Shell)
# Author: Thomas Sostarics, adapted from trigger2tg script from Chun Chan
# Created: 5 May 2023
# Last Updated: 25 October 2023
################################################################################
# This script loads a stereo sound file where channel 1 is the recordinga and
# channel 2 contains trigger waves separating the utterances and the recording's
# associated prompt file. The script then converts the stereo file to Mono and
# creates a textgrid with 1 tier `utterances` which contains the utterances 
# specified in the prompt file
################################################################################
form Convert to Mono and set textgrid from triggers
	comment Input stereo sound path and desired output directory
	text soundFile C:/Users/Thomas/Desktop/c_a_230531_006.wav
	text outputDir C:/Users/Thomas/Desktop/out
	comment Input prompt text file and csv filepath containing lookup table
	text textFile C:/Users/Thomas/Desktop/c_a_230531_006.txt
	comment Enter delta and window length
	real delta 0.02
	real jumpAheadWindow 0.1
endform

# Load prompts
if textFile$ <> ""
    prompts = Read Strings from raw text file: textFile$
else
	exit Script exited, no textfile entered
endif


# Load sound file
if soundFile$ <> ""
    sound = Read from file: soundFile$
    selectObject: sound
    objName$ = selected$("Sound")

	# Extract the filename from its path
    rindexBack = rindex(soundFile$, "\")
    rindexFront = rindex(soundFile$, "/")    
    slashIndex = rindexBack
    if rindexFront > rindexBack
        slashIndex = rindexFront
    endif
    outputFilename$ = right$(soundFile$, (length(soundFile$) - slashIndex))
else
	exit Script exited.
endif
writeInfoLine: outputFilename$

# Set clean output directory
if outputDir$ == ""
	exit Script exited. You did not select a folder.
else
	outputDir$ = outputDir$ + "/";
endif

#create textgrid
selectObject: sound
To TextGrid: "utterance", ""
tg = selected("TextGrid")

#extract channels
selectObject: sound
sound1 = Extract one channel: 1
selectObject: sound
sound2 = Extract one channel: 2
selectObject: sound
Remove

#get threshold for triggers
selectObject: sound2
maxAmplitude = Get maximum: 0, 0, "Sinc70"
minAmplitude = Get minimum: 0, 0, "Sinc70"

# If the trigger wave is inverted, then the peak will actually be
# a valley, so we need to flip the whole trigger channel.
if abs(maxAmplitude) < abs(minAmplitude)
	selectObject: sound2
	Formula: "-1*self"
	maxAmplitude = -1*minAmplitude
endif

threshold = maxAmplitude/1.5
endTime = Get end time

#look for triggers, add intervals to textgrid
n = 0
appendInfoLine: "Placing boundaries..."
while n <= endTime
	selectObject: sound2
	amplitude = Get value at time: 1, n, "Sinc70"
	amplitudeSearch = Get maximum: n, n + jumpAheadWindow, "Sinc70"
	if amplitudeSearch >= threshold
		peakTime = Get time of maximum: n, n + jumpAheadWindow + delta, "Sinc70"
		selectObject: tg
		Insert boundary: 1, peakTime
		n = n + jumpAheadWindow + delta * 2
		appendInfoLine: peakTime
	else
		n = n + jumpAheadWindow
	endif
endwhile

selectObject: tg

#assign text to TextGrid intervals
selectObject: prompts
numberOfStrings = Get number of strings
for n from 1 to numberOfStrings
	selectObject: prompts
	currentString$ = Get string: n
	selectObject: tg
	Set interval text: 1, n+1, currentString$
endfor


#save files
selectObject: sound1
appendInfoLine: "Saving file:" + outputDir$ + outputFilename$
Save as WAV file: outputDir$ + outputFilename$
selectObject: tg
Save as text file: outputDir$ + (outputFilename$ - ".wav" + ".TextGrid")


#cleanup
selectObject: sound1
plusObject: sound2
plusObject: tg
plusObject: prompts
Remove