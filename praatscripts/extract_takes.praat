###################################################################
# Extract multiple takes from long recording
# Thomas Sostarics 28 July 2022
#
# This script assumes an audio file with an 
# associated textgrid with three interval tiers:
#  1) Intervals mark region of target utterances
#  2) Intervals mark individual takes/attempts of
#     the target utterance (ie nested within 1).
#     Intervals marking takes to extract must be
#     something non-silent, but this information
#     isn't saved at all. I use single-digit numbers
#     roughly corresponding to how good I think the
#     attempt is.
#  3) Intervals must be the same as (1), but the
#     labels should be shortened for use as filenames
#
###################################################################
# Example
# 
#  Input: jackjill_HLL.wav, jackjill_HLL.TextGrid
#  |                waveform               |
#  |               spectrogram             |
#  | | jack is mad |     |  jill is sad |  | 1: target utterances
#  |   |1|  |2|              |1| |2| |1|   | 2: takes
#  | |     jack    |     |      jill    |  | 3: filenames
#  Output:
#   -jack_HLL_001.wav, jack_HLL_001.TextGrid
#  |                waveform               |
#  |               spectrogram             |
#  |               jack is mad             | 1: target utterances
#   -jack_HLL_002.wav, jack_HLL_002.TextGrid
#   -jill_HLL_001.wav, jill_HLL_001.TextGrid
#   -jill_HLL_002.wav, jill_HLL_002.TextGrid
#   -jill_HLL_003.wav, jill_HLL_003.TextGrid
###################################################################
# Notes
#
# - This script implicitly assumes a _ delimeter in the filename
#   such that the final portion of the filename denotes a condition
#   of some sort (here, an intonation contour). Look around line
#   137 if you want to remove or customize this behavior
# - This script was made with the intention of feeding the output
#   files and textgrids to the montreal forced aligner
#
###################################################################

form Extract Multiple Takes
	comment Directory of input sound files and textgrids
	text fromDir D:\OneDrive - Northwestern University\_FromNUBox\Research\Dissertation\Part1\Exp1\Recordings\01_Mono
	comment Directory of output sound files and textgrids
	text outDir D:\OneDrive - Northwestern University\_FromNUBox\Research\Dissertation\Part1\Exp1\Recordings\02_PossibleRecordings
endform

# Define main procedure to use in loop later
procedure extract_and_name_takes: .groupInterval, transcription$
	# If we've identified a section with recordings, get the label and filename
	.groupStart = Get start time of interval: 1, .groupInterval
	.groupEnd = Get end time of interval: 1, .groupInterval
	groupFileName$ = Get label of interval: 3, .groupInterval
	i = 1

	# Extract the group audio and textgrid region
	selectObject: "Sound " + objname$
	Extract part: .groupStart, .groupEnd, "rectangular", 1, "no"
	selectObject: "TextGrid " + objname$
	Extract part: .groupStart, .groupEnd, "no"

	# Replace the numeric annotations with the original transcription,
	# this will allow us to use the forced aligner on individual files
	selectObject: "TextGrid " + objname$ + "_part"
	.numberOfTakeIntervals = Get number of intervals: 2	
	#Replace interval texts: 2, 1, 0, "[0-9]", transcription$, "Regular Expressions"

	for .take from 1 to .numberOfTakeIntervals
		selectObject: "TextGrid " + objname$ + "_part"
		takeLabel$ = Get label of interval: 2, .take
		if takeLabel$ <> ""
			# Get start and end times for this take
			.takeStart = Get start time of interval: 2, .take
			.takeEnd = Get end time of interval: 2, .take
			
			# Extract sound and textgrid for take
			selectObject: "Sound " + objname$ + "_part"
			Extract part: .takeStart, .takeEnd, "rectangular", 1, "no"
			selectObject: "TextGrid " + objname$ + "_part"
			Extract part: .takeStart, .takeEnd, "no"

			# Remove unneeded tiers
			selectObject: "TextGrid " + objname$ + "_part" + "_part"
			Remove tier: 2
			Remove tier: 3


			# Add take index with padded zeros, construct file name
			take_i$ = right$("000" + string$(i), 3)
			filename$ = outDir$ + groupFileName$ + "_" + tune$ + "_" + take_i$
			i = i + 1

			# Save take as a new file, then remove take objects
			selectObject: "Sound " + objname$ + "_part" + "_part"
			Save as WAV file: filename$ + ".wav"
			selectObject: "TextGrid " + objname$ + "_part" + "_part"
			Save as text file: filename$ + ".TextGrid"

			plusObject: "Sound " + objname$ + "_part" + "_part"
			Remove
		endif
	endfor

	# After all the takes in this group have been saved,
	# remove the group sound objects
	selectObject: "Sound " + objname$ + "_part"
	plusObject: "TextGrid " + objname$ + "_part"
	Remove
endproc

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
	## Load files
	select Strings list
	filename$ = Get string: ifile
	Read from file: fromDir$ + filename$

	# Get the object name by chopping off the file extension,
	# Get the tune by taking the last section of the name (eg exp1_raw_HLL -> HLL)
	objname$ = left$(filename$, length(filename$)-4)
	tune$ = right$(objname$, length(objname$) - rindex(objname$, "_"))

	Read from file: fromDir$ + objname$ + ".TextGrid"

	selectObject: "TextGrid " + objname$
	numberOfGroupIntervals = Get number of intervals: 1
	numberOfTakeIntervals = Get number of intervals: 2

	# For each recording group in the first tier
	for igroup from 1 to numberOfGroupIntervals
		selectObject: "TextGrid " + objname$
		groupName$ = Get label of interval: 1, igroup
		# If group name is not empty, extract and save all the takes denoted by the second tier
		if groupName$ <> ""
			@extract_and_name_takes: igroup, groupName$
		endif
	endfor
endfor

select all
Remove