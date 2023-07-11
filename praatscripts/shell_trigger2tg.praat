################################################################################
# Triggers to TextGrids (Shell)
# Author: Thomas Sostarics, adapted from trigger2tg script from Chun Chang
# Created: 5 May 2023
# Last Updated: 6 May 2023
################################################################################
# This script loads a stereo sound file where channel 1 is the recordinga and
# channel 2 contains trigger waves separating the utterances and the recording's
# associated prompt file. Also, script file loads a CSV file that matches up the
# utterances to preset desired filename patterns. The script then converts the
# stereo file to Mono and creates a textgrid with 3 tiers:
#  - utterance: Contains the utterances contained in the prompt ifle
#  - take: A blank tier for manual annotations later
#  - file: A tier with the same intervals as the utterance tier but with file 
#          patterns as given by the csv file
################################################################################
form Convert to Mono and set textgrid from triggers
	comment Input stereo sound path and desired output directory
	text soundFile ../00_Raw/c_a_230530_005.wav
	text outputDir ../01_Mono/
	comment Input prompt text file and csv filepath containing lookup table
	text textFile ../../recording_prompts/c_a_230530_005.txt
	text csvFile ../../recording_prompts/answer_prompts_critical.csv
	comment Enter column names to look up and retrieve
	text searchColName answer
	text retrieveColName file_pattern
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

# Load csv file as table
if csvFile$ <> ""
	lookupTable = Read Table from comma-separated file: csvFile$
else
	exit Script exited.
endif 

# Load sound file
if soundFile$ <> ""
    sound = Read from file: soundFile$
    selectObject: sound
    objName$ = selected$("Sound")
    # Eg c_a_230503_001, extract "_230503_001"
    sessionDate$ = right$(objName$, 11)

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


# Set clean output directory
if outputDir$ == ""
	exit Script exited. You did not select a folder.
else
	outputDir$ = outputDir$ + "/";
endif

# Helper procedure to get the appropriate file pattern from the table
procedure get_file_pattern: .searchString$
	selectObject: lookupTable
	rowNumber = Search column: searchColName$, .searchString$
	appendInfoLine: rowNumber
	appendInfoLine: retrieveColName$
	appendInfoLine: .searchString$
	appendInfoLine: searchColName$
	.filePattern$ = Get value: rowNumber, retrieveColName$
	.filePattern$  = .filePattern$ + sessionDate$
endproc

# Helper proc to split on the __ delimeter
procedure split_tune: .utterance$
	idx = index(.utterance$, "__")
	if idx > 0
		.utterance$ = left$(.utterance$, idx-1)
	endif
endproc

#script parameters
#delta = 0.02
#jumpAheadWindow = 0.1

#load sound file

#create textgrid
selectObject: sound
To TextGrid: "utterance take", ""
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
#	if amplitude >= threshold
#		selectObject: tg
#		Insert boundary: 1, n
#		n = n + jumpAheadWindow
#	else
#		n = n + delta
#	endif
endwhile

selectObject: tg
Duplicate tier: 1, 3, "file"

#assign text to TextGrid intervals
selectObject: prompts
numberOfStrings = Get number of strings
for n from 1 to numberOfStrings
	selectObject: prompts
	currentString$ = Get string: n
	@get_file_pattern: currentString$, lookupTable
	@split_tune: currentString$
	selectObject: tg
	Set interval text: 1, n+1, split_tune.utterance$
	# Set the file name from the spreadsheet
	Set interval text: 3, n+1, get_file_pattern.filePattern$
endfor


#save files
selectObject: sound1
Save as WAV file: outputDir$ + outputFilename$
selectObject: tg
Save as text file: outputDir$ + (outputFilename$ - ".wav" + ".TextGrid")


#cleanup
selectObject: sound1
plusObject: sound2
plusObject: tg
plusObject: prompts
Remove







