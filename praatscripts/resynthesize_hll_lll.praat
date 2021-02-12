#####################################
# Resynthesize HLL and LLL Pairs
# Thomas Sostarics 10/9/2020
# 
# Resynthesizes all the files in a directory
# to have HLL and LLL contours, and saves
# the resynthesized files in the given directory
#
# Thanks to Chad Vicenik, whose flat
# resynthesis script I used as a reference
#
#####################################
#           INSTRUCTIONS
# 0. Create a text grid for each wav
#    file in your directory with 2
#    tiers: an internal and a point
#    On the point tier, mark the start
#    of the waveform with a #. Mark any
#    pre-stressed syllables with another
#    #. Mark the NPA with a *. Mark the
#    phrase tone with a - and the boundary
#    (end of waveform) with a %.
# 1. Run this script, enter the directory
#    containing all of your sound and textgrids
# 2. Enter the index for the tier (should be 2
#    but just in case you have some modification)
# 3. Enter the midlevel frequency of the speaker
# 4. If you want to resynthesize the wav file
#    to have a flat contour BEFORE doing
#    the resynthesized H/LLL contours,
#    write 1 in the to flat box (otherwise, 0)
# 5. Enter the min and max of the manipulation
#    range, for a male speaker 50 and 350 is given   
#####################################

form HLL LLL Resynthesis
	comment Directory of sound files with textgrids
	text outDir C:\Users\tsost\Box\Research\QP\Recordings\scripttest
	comment Directory for output sound files
	text saveDir C:\Users\tsost\Box\Research\QP\Recordings\scripttest\out
	comment Please enter the point tier number
	natural tiernum 2
	comment Please enter a base frequency
	natural spkr_freq 100
	comment Would you like to resynthesize to flat first? (1 for yes 0 for no)
	natural to_flat 1
	comment Please enter manipulation range
	natural min 50
	natural max 350
endform

# Check for final slash
if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif
if right$(saveDir$, 1) <> "\"
	saveDir$ = saveDir$ + "\"
endif

filenames = Create Strings as file list: "fileList", outDir$ + "*.wav"
numberOfFiles = Get number of strings
textgrids = Create Strings as file list: "tgList", outDir$ + "*.TextGrid"
numberOfGrids = Get number of strings

if numberOfFiles <> numberOfGrids
	echo "WARNING: Number of files != number of text grids in directory."
endif

for ifile to numberOfFiles
	selectObject: filenames
	filename$ = Get string: ifile

	# Open the files
	Read from file: outDir$ + filename$
	To Manipulation: 0.1, min, max
	filename$ = left$(filename$, length(filename$)-4)
	Read from file: outDir$ + filename$ + ".TextGrid"

	# Any spaces in the file name needs to be replaced
	# as underscores so praat can reference them in
	# the objects pane
	objname$ = replace$(filename$, " ", "_", 0)

	# Create flat manipulation if needed
	if to_flat = 1
		selectObject: "Sound " + objname$
		start = Get start time
		end = Get end time
		Create PitchTier: objname$, start, end
		Add point: start, spkr_freq
		Add point: end, spkr_freq

		# Combine and save the resulting file:

		selectObject: "Manipulation " + objname$
		plusObject: "PitchTier " + objname$
		Replace pitch tier
		selectObject: "Manipulation " + objname$
		Get resynthesis (PSOLA)
		Rename: objname$ + "_flat"
		selectObject: "Sound " + objname$
		Remove
		selectObject: "Sound " + objname$ + "_flat"
		Rename: objname$
		selectObject: "PitchTier " + objname$
		Remove
	endif

	# Get number of landmarks on point tier
	selectObject: "TextGrid " + objname$
	nPoints = Get number of points: tiernum

	# Create a PitchTier object
	selectObject: "Sound " + objname$
	Create PitchTier: objname$, start, end
	
	# Add all the pitch points
	for iPoint to nPoints
		selectObject: "TextGrid " + objname$
		cur_label$ = Get label of point: tiernum, iPoint
		cur_time = Get time of point: tiernum, iPoint
		selectObject: "PitchTier " + objname$
		if cur_label$ = "#"
			Add point: cur_time, spkr_freq
		elsif cur_label$ = "*"
			Add point: cur_time, 130
		elsif cur_label$ = "-"
			Add point: cur_time, 85
		elsif cur_label$ = "%"
			Add point: cur_time, 80
		endif
	endfor
	
	# Perform the resynthesis
	selectObject: "Manipulation " + objname$
	plusObject: "PitchTier " + objname$
	Replace pitch tier
	selectObject: "Manipulation " + objname$
	Get resynthesis (PSOLA)
	Save as WAV file: saveDir$ + filename$ + "_hll.wav"
	plusObject: "PitchTier " + objname$
	Remove

	# Create a PitchTier object
	selectObject: "Sound " + objname$
	Create PitchTier: objname$, start, end
	
	# Add all the pitch points
	for iPoint to nPoints
		selectObject: "TextGrid " + objname$
		cur_label$ = Get label of point: tiernum, iPoint
		cur_time = Get time of point: tiernum, iPoint
		selectObject: "PitchTier " + objname$
		if cur_label$ = "#"
			Add point: cur_time, spkr_freq
		elsif cur_label$ = "*"
			Add point: cur_time, 85
		elsif cur_label$ = "-"
			Add point: cur_time, 85
		elsif cur_label$ = "%"
			Add point: cur_time, 80
		endif
	endfor
	
	# Perform the resynthesis
	selectObject: "Manipulation " + objname$
	plusObject: "PitchTier " + objname$
	Replace pitch tier
	selectObject: "Manipulation " + objname$
	Get resynthesis (PSOLA)
	Save as WAV file: saveDir$ + filename$ + "_lll.wav"
	plusObject: "PitchTier " + objname$
	Remove
endfor

select all
Remove





