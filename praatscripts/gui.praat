################################################################################
# GUI for selecting intervals
# Author: Thomas Sostarics
# Created: 8 June 2023
# Last Updated: 22 June 2023
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
#
# This script was written for a particular workflow in mind (tone annotation)
# but can be modified as needed.
################################################################################
# created: idk 6/8/2023
# modified: 6/22/2023
form Quick Annotate Files
	comment Directory of input sound files
	text inSoundDir ../02_PossibleRecordings
	comment Directory of input textgrid files
	text inTgDir ../02_PossibleRecordings/MFA_textgrids
	comment Directory of output sound files and textgrids
	text outDir ../02_PossibleRecordings/AnnotatedTextgrids
	comment Should files already in the output directory be skipped?
	boolean skipCompleted 1
endform

# Clean paths
inSoundDir$ = inSoundDir$ + "/"
inTgDir$ = inTgDir$ + "/"
outDir$ = outDir$ + "/"

# GUI button options
optionVector# = {1, 1, 2, 0.8, 0.5, 0.33, 0.25}

# This is the main procedure that loads a pause form
# with various buttons. For my purposes I just want buttons
# that move the cursor to a specified percentage of the selected
# interval. For example, select the stressed syllable and place
# the cursor at 80% of that region.
procedure annotate_file_gui: .editorname$
  while fileDone <> 1
    # Bring up menu
    beginPause: "Select option below"
    userOption = endPause: "Exit", "Next", "Prev", "0.80", "0.50", "0.33", "0.25", 2, 1

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
  if nTiers < 5
    Insert point tier: nTiers + 1, "tobi"
    Insert point tier: nTiers + 2, "notes"
  
  # Extract the boundary tone, either h or l
  edgeToneIndex = index_regex(editorName$, "(ll|lh)_")
  boundaryTone$ = mid$(editorName$, edgeToneIndex+1, 1)
  
  # Get the boundary tone time, this will be the start of the last
  # silent interval on the phone tier, or, if there is no final silence,
  # the end of the last phone interval on that tier (rare but can happen)
  selectObject: .tgObj
  nPhones = Get number of intervals: 2 
  finalLabel$ = Get label of interval: 2, nPhones
  boundaryTime = Get start time of interval: 2, nPhones  
  if finalLabel$ <> ""
    boundaryTime = Get end time of interval: 2, nPhones
  endif

  if boundaryTone$ = "h"
    boundaryLabel$ = "H%"
  else
    boundaryLabel$ = "L%"
  endif

  Insert point: 4, boundaryTime, boundaryLabel$
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
endif

writeInfoLine: "Skipping " + string$(startFile) + " files"

for ifile from startFile to numberOfFiles
 if abortScript = 0
  select Strings list
  tgFilename$ = Get string: ifile
  wavFilename$ = left$(tgFilename$, length(tgFilename$)-8) + "wav"
  paIndex = index_regex (tgFilename$, "_(h|lhs|lsh)l")  
  paPattern$ = mid$(tgFilename$, paIndex+1, 2)

  if paPattern$ = "hl"
   pa$ = "H*"
  elsif paPattern$ = "lh"
   pa$ = "+H*"
  else
   pa$ = "+H"
  endif

  appendInfoLine: tgFilename$
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
    nuclearWordi = Get number of intervals: 1
    nuclearWordi = nuclearWordi - 1
    startTime = Get start time of interval: 1, nuclearWordi
    endTime = Get end time of interval: 1, nuclearWordi    
    nucDuration = endTime - startTime
    hasPeak = Count points where: 5, "matches (regex)", "p|pe"
    # Open the editor window, run annotation procedure
    selectObject: tgObj
    plusObject: wavObj
    View & Edit

    if hasPeak = 0
     editor: editorName$
      Select: (startTime + nucDuration*0.2), (startTime+nucDuration*0.6)
      Move cursor to maximum pitch
      Move cursor to nearest zero crossing
      pointTime = Get cursor
     endeditor

     selectObject: tgObj
     Insert point: 4, pointTime, pa$
     Insert point: 5, pointTime, "p"
    endif

    @annotate_file_gui: editorName$

    if abortScript = 0
    # When we return from the annotation procedure, 
    # close the editor window and save the final
    # textgrid file
    editor: editorName$
    Close
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