#######################################
# Resynthesize Bivariate Continuum
# Thomas Sostarics 08/13/2022
# Last Updated: 08/13/2022
#######################################

form Resynthesize Continuum
	comment Directory of sound files
	text fromDir ..\altest\input
	comment Directory of TextGrid files
	text tgFromDir ..\altest\input\TextGrids
	comment Directory to save output files
	text outDir ..\altest\output
	text ptDir ..\altest\output\PitchTiers
	text tgToDir ..\altest\output\TextGrids
	comment Low Hz value for Pitch Accent
	positive lowHz 70
	comment High Hz value for Pitch Accent
	positive highHz 110
	comment Number of continuum steps
	positive nSteps 5
	comment ERB differentials
	real lowErb -0.25
	real highErb 2
	comment Percent of post-tonic syllable duration to place L- target
	real pctNonStressed 0.3
	comment Alignment of Pitch accent (as decimal % of first syllable duration)
	positive paAlignment 1.0
	comment Time for start of PA rise (in seconds relative to start of syl 1, negative)
	real fromPoint -0.050
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
if right$(tgFromDir$, 1) <> "\"
	tgFromDir$ = tgFromDir$ + "\"
endif
if right$(tgToDir$, 1) <> "\"
	tgToDir$ = tgToDir$ + "\"
endif
if right$(ptDir$, 1) <> "\"
	ptDir$ = ptDir$ + "\"
endif

## Make the continuum values
pavals# = from_to_count# (lowHz, highHz, nSteps)
erbvals# = from_to_count# (lowErb, highErb, nSteps)
btvals# = zero# (nSteps)

for i from 1 to size (btvals#)
	btvals# [i] = erbToHertz(hertzToErb(lowHz) + erbvals# [i])
endfor

midPitch = mean (pavals#)

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

	selectObject: "Sound " + objname$
	To Manipulation: 0.01, min, max

	selectObject: "TextGrid " + objname$
	stressedSylStart = Get start time of interval: 4, 2
	stressedSylEnd = Get end time of interval: 4, 2
	stressedSylDur = stressedSylEnd - stressedSylStart
	nIntervals = Get number of intervals: 4
	btTime = Get start time of interval: 4, nIntervals
	paTime = (paAlignment - 1) * stressedSylDur + stressedSylEnd

	# Calculate where the additional earlier low target should go
	sylIndex = nIntervals - 1
	if nIntervals = 5
		sylIndex = nIntervals - 2
	endif
	finalSylStart = Get start time of interval: 4, sylIndex
	finalSylDur = btTime - finalSylStart
	lowPhraseTime = (pctNonStressed * finalSylDur) + finalSylStart	

	for pai from 1 to size (pavals#)
		paval = pavals# [pai]
		for bti from 1 to size (btvals#)
			btval = btvals# [bti]

			# Select sound file and create new manipulation
			selectObject: "Sound " + objname$
			tmax = Get total duration
			To Manipulation: 0.01, min, max
			selectObject: "Sound " + objname$
			Create PitchTier: objname$, 0.0, tmax

			# Add the new pitch values
			Add point: 0.0, midPitch
			Add point: stressedSylStart + fromPoint, midPitch
			Add point: paTime, paval
			if btval < paval
				Add point: lowPhraseTime, btval
			endif
			Add point: btTime, btval

			# Perform the resynthesis and save new file
			selectObject: "Manipulation " + objname$
			plusObject: "PitchTier " + objname$
			Replace pitch tier
			selectObject: "Manipulation " + objname$
			Get resynthesis (PSOLA)
			selectObject: "Sound " + objname$
			Save as WAV file: outDir$ + objname$ + "_" + string$(pai) + "_" + string$(bti) + ".wav"
			
			# Remove the resynthesis manipulation and pitchtier we made
			selectObject: "Manipulation " + objname$
			plusObject: "PitchTier " + objname$
			Remove

			# Create a new manipulation from the resynthesized file
			# so we can extract the new signal's pitch tier
			selectObject: "Sound " + objname$
			To Manipulation: 0.01, min, max
			Extract pitch tier
			selectObject: "PitchTier " + objname$
			Save as text file: ptDir$ + objname$ + "_" + string$(pai) + "_" + string$(bti) + ".PitchTier"
			
			# Remove the new Sound, PitchTier, and Manipulation we just made
			# Important: if you don't remove the sound object here the later resyntheses
			#            will apply on top of the resynthesized file! like jpeg compression artifacts
			selectObject: "PitchTier " + objname$
			plusObject: "Manipulation " + objname$
			plusObject: "Sound " + objname$
			Remove

			# Copy the TextGrid into the new directory. This will yield many copies
			# of the same TextGrid but honestly it's easier this way, space is cheap
			# and most analyses/wrangling assumes a 1:1 correspondence original
			# wav files and textgrid files
			selectObject: "TextGrid " + objname$
			Save as text file: tgToDir$ + objname$ + "_" + string$(pai) + "_" + string$(bti) + ".TextGrid"
		endfor
	endfor
selectObject: "Sound " + objname$
Remove
endfor

writeFileLine: "resynthesis_parameters_exp1.csv", "index, pa_val, bt_val"
for i from 1 to size (pavals#)
	appendFileLine: "resynthesis_parameters_exp1.csv", i, ", ", pavals# [i], ", ", btvals# [i]
endfor

select all
Remove