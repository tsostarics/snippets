################################################################################
# GUI for time-aligned duration manipulations 
# Author: Thomas Sostarics
# Created: 16 July 2023
# Last Updated: 17 July 2023
################################################################################
# This script loads audio, textgrids, pitchtiers, and duration tiers one by one.
# Two windows are opened:
#   - A TextGrid editor (Sound+TextGrid objects)
#   - A Manipulation editor from the Sound object with the pitchtier replaced
#     by the loaded pitchtier
# The task here is to do manual duration manipulations of desired intervals,
# where the intervals are ideally plucked from the textgrid intervals.
# After a selection is made in the TextGrid editor, you can press a button
# on the floating menu, which will then drop points at the appropriate places
# to shrink or stretch the interval accordingly. The options:
# [Exit] Quits the script, does not save current file
# [Next] Saves the current DurationTier in the output directory, moves to next file
# [Prev] Saves the current DurationTier in the output directory, moves to previous file
# [X] First, select an interval in the TextGrid editor, e.g., from time [1s, 2s].
#     Selecting one of these buttons, say the 0.8 button, will place DurationTier
#     points like so:
#
#     -------o            o------  1.0 <-- no change in duration
#            |\          /|
#            | o--------o |        0.8 <-- userVal
#            | |        | |
#          1-e 1        2 2+e
#  Where `e` denotes a value epsilon that is used as a infinitesimally small distance
#  which defaults to epsilon=0.000001s (a hundredth of a millisecond, a microsecond)
# [Clear] Delete all durationtier points in the current manipulation editor
# [Nudge+]
# Tips:
#
# This script was written for a particular workflow in mind (tone annotation)
# but can be modified as needed.
################################################################################
# created:  7/16/2023
# modified: 7/17/2023
################################################################################
form Quick Annotate Files
	comment Directory of input sound files
	text inSoundDir ../02_PossibleRecordings
	comment Directory of input textgrid files
	text inTgDir ../02_PossibleRecordings/AnnotatedTextgrids
	comment Directory of input pitchtiers
	text inPtDir ../02_PossibleRecordings/ResynthPitchTiers3
	comment Directory of output sound files and textgrids
	text outDtDir ../02_PossibleRecordings/ManualDurationTiers
	comment Should files already in the output directory be skipped?
	boolean skipCompleted 1
  real epsilon 0.000001
endform

# Clean paths
inSoundDir$ = inSoundDir$ + "/"
inTgDir$ = inTgDir$ + "/"
inPtDir$ = inPtDir$ + "/"
outDtDir$ = outDtDir$ + "/"

twoThirds = 2/3
oneThird = 1/3
# GUI button options
optionVector# = {1, 1, 2, 3, 0.9, 0.8, twoThirds, 0.5, oneThird, 0.25}

# This is the main procedure that loads a pause form
# with various buttons. For my purposes I just want buttons
# that move the cursor to a specified percentage of the selected
# interval. For example, select the stressed syllable and place
# the cursor at 80% of that region.
procedure annotate_file_gui: .tgEditorName$, .manEditorName$
  while fileDone <> 1
    # Bring up menu
    beginPause: "Select option below"
     comment: "Enter a manual percentage here if necessary"
     positive: "manualRelativeDuration", 1.0
    userOption = endPause: "Exit", "Next", "Prev", "Manual", "0.90", "0.80", "2/3", "0.50", "1/3", "0.25", 2, 1

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
    # If user specified a manual value, use the entered value. Otherwise
    # it will be assumed that a button with a value was picked
        if userOption = 4
            userVal = manualRelativeDuration
        endif
    # Get the interval timepoints from the textgrid editor
    editor: .tgEditorName$
      selectionStart = Get start of selection
      selectionEnd = Get end of selection
    endeditor
    # Use the extracted timepoints to place duration tier points
    editor: .manEditorName$
      # First delete any points within the region
      Select: selectionStart - 2*epsilon, selectionEnd + 2*epsilon
      Remove duration point(s)
      Add duration point at: selectionStart - epsilon, 1.0
      Add duration point at: selectionStart, userVal
      Add duration point at: selectionEnd, userVal
      Add duration point at: selectionEnd + epsilon, 1.0
    endeditor
    endif
  endwhile
endproc

# Get the list of files we need to work through
Create Strings as file list: "list", inPtDir$ + "*.PitchTier"
numberOfFiles = Get number of strings

# Set starting values for flags
alreadyDone = 0
fileDone = 0
doPrev = 0
repeatFile = 0
abortScript = 0
alreadyAnnotated = 0

# At start of script, skip all the files that already have duration tiers
# in the output directory
startFile = 0
if skipCompleted
repeat
  startFile = startFile + 1
  select Strings list
  filename$ = Get string: startFile 
  alreadyDone = fileReadable(outDtDir$ + left$(filename$, length(filename$) - 9) + "DurationTier")
until alreadyDone = 0 or startFile = numberOfFiles
endif

writeInfoLine: "Skipping " + string$(startFile) + " files"

for ifile from startFile to numberOfFiles
 if abortScript = 0
  select Strings list
  appendInfoLine: "blah"
  ptFilename$ = Get string: ifile
  objName$ = left$(ptFilename$, length(ptFilename$) - 10)
  wavFilename$ = objName$ + ".wav"
  tgFilename$ = objName$ + ".TextGrid"
  dtFilename$ = objName$ + ".DurationTier"
  
  appendInfoLine: ptFilename$
  # First check if the corresponding wav file exists
  # and that it's not already processed
  wavExists = fileReadable(inSoundDir$ + wavFilename$)

  if wavExists
    # Load the sound and textgrid files
    wavObj = Read from file: inSoundDir$ + wavFilename$
    alreadyAnnotated = fileReadable(outDtDir$ + dtFilename$)
  
    repeatFile = 0

    tgObj = Read from file: inTgDir$ + tgFilename$
    ptObj = Read from file: inPtDir$ + ptFilename$

    # Get the name of the tg editor we'll be working with
    # (it's just "TextGrid " + name of object)
    selectObject: tgObj
    tgEditorName$ = selected$(1)

    # Create the manipulation object; we'll need to replace the
    # duration tier if one exists already. We'll also need to
    # replace the pitch tier with the one we made in R.
    selectObject: wavObj
    Scale peak: 0.99
    Scale intensity: 70.0
    manObj = To Manipulation: 0.01, 40, 200
    
    selectObject: manObj
    manEditorName$ = selected$(1)

    # Load the duration tier if it exists, then replace if it does
    if alreadyAnnotated = 1
      dtObj = Read from file: outDtDir$ + dtFilename$
      selectObject: manObj
      plusObject: dtObj
      Replace duration tier
    else
    # Dummy value, not really used in this case
      selectObject: manObj
      dtObj = Extract duration tier
    endif
    
    # Replace the pitch tier
    selectObject: manObj
    plusObject: ptObj
    Replace pitch tier

    # Open the editor window, run annotation procedure
    selectObject: tgObj
    plusObject: wavObj
    View & Edit

    selectObject: manObj
    View & Edit

    @annotate_file_gui: tgEditorName$, manEditorName$

    if abortScript = 0

    # When we return from the annotation procedure, 
    # close the editor windows
    editor: tgEditorName$
    Close
    editor: manEditorName$
    Close

    # Remove old/dummy duration tier object
    selectObject: dtObj
    Remove

    # Extract up to date duration tier
    selectObject: manObj
    dtObj = Extract duration tier
    selectObject: dtObj
    Save as text file: outDtDir$ + dtFilename$
    
    # Clean up objects
    selectObject: tgObj
    plusObject: wavObj
    plusObject: manObj
    plusObject: ptObj
    plusObject: dtObj
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