#script parameters
delta = 0.02
jumpAheadWindow = 0.1

#load sound file
pauseScript: "Select sound file"
soundFile$ = chooseReadFile$: "Open a sound file"
if soundFile$ <> ""
    sound = Read from file: soundFile$
	outputFilename$ = right$(soundFile$, (length(soundFile$) - rindex(soundFile$, "\")))
else
	exit Script exited.
endif

#load text file containing prompts/materials used in the recording
pauseScript: "Select prompt file"
textFile$ = chooseReadFile$: "Open a text file"
if textFile$ <> ""
    prompts = Read Strings from raw text file: textFile$
else
	exit Script exited.
endif

pauseScript: "Select output folder"
#directory to save processed wave file and textgrids to
outputDir$ = chooseDirectory$ ("Select output folder")
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
threshold = maxAmplitude/2
endTime = Get end time

#look for triggers, add intervals to textgrid
n = 0
while n <= endTime
	selectObject: sound2
	amplitude = Get value at time: 1, n, "Sinc70"
	if amplitude >= threshold
		selectObject: tg
		Insert boundary: 1, n
		n = n + jumpAheadWindow
	else
		n = n + delta
	endif
endwhile

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
Save as WAV file: outputDir$ + outputFilename$
selectObject: tg
Save as text file: outputDir$ + (outputFilename$ - ".wav" + ".TextGrid")


#cleanup
selectObject: sound1
plusObject: sound2
plusObject: tg
plusObject: prompts
Remove

clearinfo
writeInfoLine: "Done!"
appendInfoLine: "Files saved to " + outputDir$







