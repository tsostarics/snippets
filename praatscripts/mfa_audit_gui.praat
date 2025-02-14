################################################################################
# GUI for auditing textgrids
# Author: Thomas Sostarics
# Created: 8 June 2023
# Last Updated: 11 February 2025
################################################################################
# This script loads audio and textgrids one by one, opens them for editing,
# then provides a floating menu where each button can be programmed to do
# something. In this case, we have:
# [Exit] Quits the script, does not save current file
# [Next] Saves the current file in the output directory, moves to next file
# [Prev] Saves the current file in the output directory, moves to previous file
# [X] First, select an interval in the editor window, e.g., from time [1s, 2s].
#     Selecting one of these buttons will then move the end of the selection to
#     be X percent of the total selected interval duration. So, if you press the
#     0.8 button then the resulting selection will be moved to [1s, 1.8s]
# [-L] Moves the left boundary of the current interval on tiers 1 (word) and 
#      2 (phone) to the nearest zero crossing of the current cursor location.
#      This also handles setting the interval text correctly. If the phone
#      has the same left boundary as the word, both are moved. If the phone is
#      starts within the word, only the phone start time is moved.
# [-R] Same as the above, but handles the right boundaries.
#
# Note that when a textgrid is saved, all boundaries/points for all tiers are 
# moved to their nearest zero crossings.
#
# This script was written for a particular workflow in mind (auditing textgrids)
# but can be adapted to whatever.
################################################################################

form Quick Annotate Files
	comment Directory of input sound files
	text inSoundDir ../02_ExtractedRecordings
	comment Directory of input textgrid files
	text inTgDir ../02_ExtractedRecordings/MFA_textgrids
	comment Directory of output sound files and textgrids
	text outDir ../02_ExtractedRecordings/Annotated_Textgrids
	comment Should files already in the output directory be skipped?
	boolean skipCompleted 1
endform

# Clean paths
inSoundDir$ = inSoundDir$ + "/"
inTgDir$ = inTgDir$ + "/"
outDir$ = outDir$ + "/"

# GUI button options
optionVector# = {1, 1, 2, 0.75, 0.5, 0.33, 0.25, 8, 9, 10}

procedure move_to_min_intensity: .editorname$
  editor: .editorname$
  selectionStart = Get start of selection
  selectionEnd = Get end of selection
  intObj = Extract visible intensity contour
  endeditor
  selectObject: intObj
  minIntTime = Get time of minimum: selectionStart, selectionEnd, "parabolic"
  removeObject: intObj
  editor: .editorname$
  Move cursor to: minIntTime
  endeditor
endproc

procedure replace_left_boundary: .editorname$
  editor: .editorname$
    Move cursor to nearest zero crossing
    boundaryAt = Get cursor
  endeditor

  selectObject: .editorname$
  interval1 = Get interval at time: 1, boundaryAt - 0.0001
  interval2 = Get interval at time: 2, boundaryAt - 0.0001
  label1$ = Get label of interval: 1, interval1 
  label2$ = Get label of interval: 2, interval2 
  
  startTime1 = Get start time of interval: 1, interval1
  startTime2 = Get start time of interval: 2, interval2

  # If the phone interval starts at the same point as the
  # word interval, then move both of the left boundaries
  # together. If the phone is within the word, move just
  # the phone boundary.
  #
  #  move these together
  #    v
  #    |      only     |
  #    | o | n | l | i |
  #        ^
  #    move only this
  if startTime2 == startTime1 
    Insert boundary: 1, boundaryAt
    Set interval text: 1, interval1, ""
    Set interval text: 1, interval1 + 1, label1$
    Remove left boundary: 1, interval1
  endif 

  Insert boundary: 2, boundaryAt 
  Set interval text: 2, interval2, ""
  Set interval text: 2, interval2 + 1, label2$
  Remove left boundary: 2, interval2 
endproc


procedure replace_right_boundary: .editorname$
  editor: .editorname$
    Move cursor to nearest zero crossing
    boundaryAt = Get cursor
  endeditor

  selectObject: .editorname$
  interval1 = Get interval at time: 1, boundaryAt - 0.0001
  interval2 = Get interval at time: 2, boundaryAt - 0.0001
  #label1$ = Get label of interval: 1, interval1 
  #label2$ = Get label of interval: 2, interval2 
  
  endTime1 = Get end time of interval: 1, interval1
  endTime2 = Get end time of interval: 2, interval2

  # If the phone interval ends at the same point as the
  # word interval, then move both of the right boundaries
  # together. If the phone is within the word, move just
  # the phone boundary.
  #
  #          move these together
  #                    v
  #    |      only     |
  #    | o | n | l | i |
  #        ^
  #    move only this
  if endTime2 == endTime1 
    Insert boundary: 1, boundaryAt
    Remove right boundary: 1, interval1 + 1
  endif 

  Insert boundary: 2, boundaryAt 
  Remove right boundary: 2, interval2 + 1
endproc


# Procedure to align intervals on a tier to the nearest zero crossing
procedure align_interval_tier: .tgObj, .soundobj, .tierNum
	# Save all the interval labels so we can re-set them later
	.ni = Get number of intervals... .tierNum
	for i to .ni
		 .label$[i] = Get label of interval... .tierNum i
	endfor

	# ni-1 since the last boundary would be the right edge, which cant be moved
	for i to .ni-1
		selectObject: .tgObj
	
	#move right boundary to closest zero crossing
	.boundary = Get end point... .tierNum i
	selectObject: .soundobj
	.zero = Get nearest zero crossing... 1 .boundary
		if .boundary != .zero
		selectObject: .tgObj
		Remove right boundary... .tierNum i
		Insert boundary... .tierNum .zero
		endif
	endfor

	# Re-set the interval albels	
	selectObject: .tgObj
	for i to .ni
	  .name$ = .label$[i]
	  Set interval text... .tierNum i '.name$'
	endfor
endproc

# Procedure to align points on a point tier to the nearest zero crossing
procedure align_point_tier: .tgObj, .soundobj, .tierNum
	# Save all the point labels so we can re-set them later
	.ni = Get number of points... .tierNum
	for i to .ni
		 .label$[i] = Get label of point... .tierNum i
	endfor

	# Go through each point
	for i to .ni
		selectObject: .tgObj
	
		# Move point to nearest zero crossing
		.boundary = Get time of point... .tierNum i
		selectObject: .soundobj
		.zero = Get nearest zero crossing... 1 .boundary
		if .boundary != .zero
			selectObject: .tgObj
			Remove point... .tierNum i
			Insert point... .tierNum .zero
		endif
	endfor

	# Re-set the point labels
	selectObject: .tgObj
	for i to .ni
	  .name$ = .label$[i]
	  Set point text... .tierNum i '.name$'
	endfor
endproc

procedure zero_align_all_tiers: .tgObj, .soundObj
  selectObject: .tgObj
  .nTiers = Get number of tiers

  for tier_i from 1 to .nTiers
    isInterval = Is interval tier: tier_i 
    if isInterval == 1
      @align_interval_tier: .tgObj, .soundObj, tier_i
    else
      @align_point_tier: .tgObj, .soundObj, tier_i
    endif
  endfor
endproc


# This is the main procedure that loads a pause form
# with various buttons. For my purposes I just want buttons
# that move the cursor to a specified percentage of the selected
# interval. For example, select the stressed syllable and place
# the cursor at 80% of that region.
procedure annotate_file_gui: .editorname$
  while fileDone <> 1
    # Bring up menu
    beginPause: "Select option below"
    userOption = endPause: "Exit", "Next", "Prev", "0.75", "0.50", "0.33", "0.25", "min int", "-L", "-R", 2, 1

    # Look up user choice
    userVal = optionVector# [userOption]

    # If user selected "Next", proceed to next file
    if userOption = 1
      fileDone = 1
      abortScript = 1
    elsif userOption = 2
      fileDone = 1
      if doPrev = 1
        repeatFile = 1
        doPrev = 0
      endif
    elsif userOption = 3
      fileDone = 1
      ifile = ifile - 2
      doPrev = 1
    elsif userOption = 8
	    @move_to_min_intensity: .editorname$
    elsif userOption = 9
      @replace_left_boundary: .editorname$
    elsif userOption = 10
      @replace_right_boundary: .editorname$
    else
    # If user selected a button, move the cursor to that multiple of the selected interval
    editor: .editorname$
      selectionStart = Get start of selection
      selectionEnd = Get end of selection
      selectionDuration = selectionEnd - selectionStart
      landmark = userVal * selectionDuration + selectionStart
      Move cursor to: landmark
      Move cursor to nearest zero crossing
    endeditor
    endif
  endwhile
endproc

# This is a preprocessing step just adding the necessary tiers for the annotations
procedure addTiers: .tgObj
  selectObject: .tgObj
  nTiers = Get number of tiers
  if nTiers < 6
    Insert point tier: nTiers + 1, "tone_c"
    Insert point tier: nTiers + 2, "tone_m"
    Insert point tier: nTiers + 1, "tone_y"
  endif
endproc



# Get the list of files we need to work through
Create Strings as file list: "list", inTgDir$ + "*.TextGrid"
numberOfFiles = Get number of strings

# Set starting values for flags
alreadyDone = 0
fileDone = 0
doPrev = 0
repeatFile = 0
abortScript = 0
alreadyAnnotated = 0

# At start of script, skip all the files that already exist
startFile = 0
if skipCompleted
  repeat
    startFile = startFile + 1
    select Strings list
    tgFilename$ = Get string: startFile 
    alreadyDone = fileReadable(outDir$ + tgFilename$)
  until alreadyDone = 0 or startFile = numberOfFiles
else
    startFile = 1
endif

writeInfoLine: "Skipping " + string$(startFile) + " files"

for ifile from startFile to numberOfFiles
 if abortScript = 0
  select Strings list
  tgFilename$ = Get string: ifile
  wavFilename$ = left$(tgFilename$, length(tgFilename$)-8) + "wav"
  
  # First check if the corresponding wav file exists
  # and that it's not already processed
  wavExists = fileReadable(inSoundDir$ + wavFilename$)

  readTgFromDir$ = inTgDir$

  if wavExists
    # Load the sound and textgrid files
    wavObj = Read from file: inSoundDir$ + wavFilename$
    alreadyAnnotated = fileReadable(outDir$ + tgFilename$)
    if alreadyAnnotated = 1
      readTgFromDir$ = outDir$
    endif

    repeatFile = 0

    tgObj = Read from file: readTgFromDir$ + tgFilename$

    # Get the name of the editor we'll be working with
    # (it's just "TextGrid " + name of object)
    selectObject: tgObj
    editorName$ = selected$(1)

    @addTiers: tgObj

    selectObject: tgObj
    plusObject: wavObj
    View & Edit

    @annotate_file_gui: editorName$

    if abortScript = 0
    # When we return from the annotation procedure, 
    # close the editor window and save the final
    # textgrid file
    editor: editorName$
    Close

    # Ensure all boundaries and points are at nearest zero crossings.
    # Note that if the word and phone boundaries are at the same location
    # then they *will* be moved to the same zero crossing.
    @zero_align_all_tiers: tgObj, wavObj
    selectObject: tgObj
    Save as text file: outDir$ + tgFilename$

    # Clean up objects
    selectObject: tgObj
    plusObject: wavObj
    Remove
    endif
  endif
 # Reset flags
  fileDone = 0
  nDoneFiles = ifile
 endif
endfor

appendInfoLine: "Total files complete so far: " + string$(nDoneFiles) + " / " + string$(numberOfFiles) + "(" + left$(string$(nDoneFiles/numberOfFiles*100), 4) + "%)"
appendInfoLine: "You annotated " + string$(nDoneFiles - startFile) + " files this session, good job!"