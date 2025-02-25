################################################################################
# GUI for time-aligned duration manipulations 
# Author: Thomas Sostarics
# Created: 16 July 2023
# Last Updated: 25 February 2023
################################################################################
# This script loads audio, textgrids and duration tiers (if they already exist).
# Two windows are opened:
#   - A TextGrid editor (Sound+TextGrid objects)
#   - A Manipulation editor for the Sound object
#
# The task here is to select intervals on the TextGrid editor that you want to
# duration manipulate. Once an interval is selected, press one of the buttons
# on the pause menu to change the relative duration of the selected region.
# For example, pressing the 2/3 button on an interval of 100ms will shorten it
# to 66.7ms (relative duration: 66.7%, pct change: -33.3%).
#
# Unlike previous iterations, this script will allow you to check the resulting
# resynthesized file(s) after applying the duration manipulation. Key to this
# is that it allows for a one-to-many relationship: one source file can be
# resynthesized to have multiple different F0 contours while applying the same
# duration manipulation to each one. After setting up the duration tier, press
# the "Check" button on the pause menu to create a chain for each resynthesized
# file. Note that this script assumes that the pitchtiers already exist for each
# source wav file and that they're all held in the same directory.
#
# Pause menu options:
# [Exit] Quits the script, does not save current file
# [Next] Saves the current DurationTier in the output directory, moves to next file
# [Prev] Saves the current DurationTier in the output directory, moves to previous file
# [Check] Creates a chain of N resynthesized files for N pitch tiers, all with the
#         same duration manipulation applied
# [Manual] Type a percentage value in the box, then press this button to apply it
#          as a duration manipulation. See below for more info.
# [X] First, select an interval in the TextGrid editor, e.g., from time [1s, 2s].
#     Selecting one of these buttons, say the 0.8 button, will place DurationTier
#     points like so:
#
#     -------o            o------  1.0 <-- no change in duration ┐
#            |\          /|                                      ├ -20% duration
#            | o--------o |        0.8 <-- userVal               ┘
#            | |        | |                (relative duration = 80%)
#          1-e 1        2 2+e
#  Where `e` denotes a value epsilon that is used as a infinitesimally small distance
#  which defaults to epsilon=0.000001s (a hundredth of a millisecond, a microsecond)
#
# This script was written for a particular workflow in mind (tone annotation)
# but can be modified as needed.
################################################################################
form GUI for making Duration Tiers
	comment Directory of input sound files
	text inSoundDir ../02_ExtractedRecordings
	comment Directory of input textgrid files
	text inTgDir ../02_ExtractedRecordings/Annotated_Textgrids
	comment Directory of input pitchtiers
	text inPtDir ../02_ExtractedRecordings/Resynthesis_Pitchtiers
	comment Directory of output sound files and textgrids
	text outDtDir ../02_ExtractedRecordings/ManualDurationTiers
	comment Should files already in the output directory be skipped?
  comment Pattern to use to load specific files (leave blank to load all files)
  text pattern hhl
	boolean skipCompleted 0
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
optionVector# = {1, 1, 2, 3, 4, twoThirds, 0.5, oneThird, 0.25}

procedure get_resynthesis_chain:
  # Ensure that the duration tier has been replaced
  selectObject: dtObj
  Remove
  selectObject: manObj
  dtObj = Extract duration tier
  selectObject: manObj, dtObj
  Replace duration tier

  .resynthObjs# = zero#(numberOfPitchTiers)
  for ipt from 1 to numberOfPitchTiers
    selectObject: manObj, ptObjs#[ipt]
    Replace pitch tier

    selectObject: manObj
    resynthObj = Get resynthesis (overlap-add)
    .resynthObjs#[ipt] = resynthObj 

    # The resynthesized object takes the name of the source wav file
    # so we need to rename it to match the pitch tier's name instead
    selectObject: ptObjs#[ipt]
    resynthName$ = selected$("PitchTier")
    selectObject: .resynthObjs#[ipt]
    Rename: resynthName$
  endfor

  selectObject: .resynthObjs#[1]
  for ipt from 1 to numberOfPitchTiers
    plusObject: .resynthObjs#[ipt]
  endfor

  Concatenate recoverably
  View & Edit

  # Cleanup
  selectObject: .resynthObjs#[1]
  for ipt from 1 to numberOfPitchTiers
    plusObject: .resynthObjs#[ipt]
  endfor
  Remove
  # Reset the pitch tier to the original one
  selectObject: manObj, rawPtObj
  Replace pitch tier
endproc


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
    userOption = endPause: "Exit", "Next", "Prev", "Check", "Manual", "2/3", "0.50", "1/3", "0.25", 2, 1

    # Look up user choice
    userVal = optionVector# [userOption]

    # If user selected "Exit", signal to abort the script
    if userOption = 1
      fileDone = 1
      abortScript = 1
    # If user selected "Next", proceed to next wav file
    elsif userOption = 2
      fileDone = 1
      if doPrev = 1
        repeatFile = 1
        doPrev = 0
      endif
    # If user selected "Prev", proceed to the previous file
    elsif userOption = 3
      fileDone = 1
      ifile = ifile - 2
      doPrev = 1
    elsif userOption = 4
      @get_resynthesis_chain
    else
    # If user specified a manual value, use the entered value. Otherwise
    # it will be assumed that a button with a value was picked
        if userOption = 5
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
Create Strings as file list: "list", inSoundDir$ + "*" + pattern$ + "*.wav"
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
  alreadyDone = fileReadable(outDtDir$ + left$(filename$, length(filename$) - 4) + "DurationTier")
until alreadyDone = 0 or startFile = numberOfFiles
else 
  startFile = 1
endif

writeInfoLine: "Skipping " + string$(startFile) + " files"

for ifile from startFile to numberOfFiles
 if abortScript = 0
  select Strings list
  wavFilename$ = Get string: ifile
  objName$ = left$(wavFilename$, length(wavFilename$) - 4)
  # wavFilename$ = objName$ + ".wav"
  tgFilename$ = objName$ + ".TextGrid"
  dtFilename$ = objName$ + ".DurationTier"
  
  # First check if the corresponding wav file exists
  # and that it's not already processed
  wavExists = fileReadable(inSoundDir$ + wavFilename$)

  if wavExists
    # Load the sound and textgrid files
    wavObj = Read from file: inSoundDir$ + wavFilename$
    alreadyAnnotated = fileReadable(outDtDir$ + dtFilename$)
  
    repeatFile = 0

    
    # The wav-to-pitchtier relation is 1-to-many, so load all
    # the pitchtiers associated with the wav file by using
    # its filename as the pattern. This assumes the pitchtier
    # files are differentiated by an affix in the filename.
    # writeInfoLine: objName$
    # appendInfoLine: inPtDir$
    Create Strings as file list: "ptList", inPtDir$ + objName$ + "*.PitchTier"
    numberOfPitchTiers = Get number of strings
    ptObjs# = zero#(numberOfPitchTiers)

    # Assuming that the pitchtiers exist for each file already, otherwise things will break
    for ipt from 1 to numberOfPitchTiers
        select Strings ptList
        ptFilename$ = Get string: ipt
        ptObjs#[ipt] = Read from file: inPtDir$ + ptFilename$
    endfor
    
    tgObj = Read from file: inTgDir$ + tgFilename$

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
    manObj = To Manipulation: 0.01, 40, 300
    rawPtObj = Extract pitch tier

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
    # selectObject: manObj
    # plusObject: ptObj
    # Replace pitch tier

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
    plusObject: dtObj
    plusObject: rawPtObj
    Remove
    
    selectObject: ptObjs#[1]
    for ipt from 1 to numberOfPitchTiers
      plusObject: ptObjs#[ipt]
    endfor
    Remove

    select Strings ptList
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