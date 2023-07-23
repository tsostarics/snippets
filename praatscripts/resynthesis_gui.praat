################################################################################
# GUI for for adding resynthesis buttons
# Author: Thomas Sostarics
# Created: 22 July 2023
# Last Updated: 22 July 2023
################################################################################
# This script is used to make quick edits to pitch pulses in a Manipulation object.
# Simply select the points you want to modify, set a nudge amount, and press the
# butons on the floating pause menu to shift the points left/right (in time) or 
# up/down (in frequency). The options:
# [Undo] Doesn't do anything.
# [Exit] Quits the script, does not save current file
# [Time -] Shift pitch points left by the given time nudge amount  (in Seconds)
# [Time +] Shift pitch points right by the given time nudge amount (in Seconds)
# [F0 +] Shift pitch points up by the given pitch nudge amount     (in Hertz)
# [F0 -] Shift pitch points down by the given pitch nudge amount   (in Hertz)
# [Scale] Apply a duration manipulation to the selected region given
#         a duration percentage amount:
#             100 = No change
#            <100 = Shrink  (eg,  80 = compress to 80% selected duration,
#                                      which is a reduction of 20%,
#                                      which is a percent change of -20%)
#            >100 = Stretch (eg, 125 = expand to 125% selected duration,
#                                      which is an increase of 25%,
#                                      which is a percent change of +25%)
# All duration manipulations use an epsilon of 1 microsecond (0.000001 s)
# and the manipulated region is aligned to the inner part of the manipulation.
# For example, for an 80% manipulation:
#
#     -------o            o------  1.0 <-- no change, duration_percentage = 100
#            |\          /|
#            | o--------o |        0.8 <-- duration_percentage = 80
#            | |        | |
#          1-e 1        2 2+e
#
# If you want to play the file after your manipulation, you can check the
# "Play on apply" box to automatically play the resynthesized signal after
# applying the transformation.
#
################################################################################
# Tips:
# Ctrl+Alt+T: Delete selected pitch pulses
# Ctrl+Alt+D: Delete selected pitch points
# Ctrl+2: Stylize pitch by 2st
################################################################################
form
    comment Manipulation object:
    natural manObject 15662
    comment Pitch range
    positive pitchMin 40
    positive pitchMax 200
    comment Export files to
    text outDir "../03_SelectedRecordings/"
endform

outDir$ = outDir$ + "/"

procedure annotate_file_gui: .prevTimeVal, .prevPitchVal, .prevPlayCheck
    # .ifile = ifile
  while fileDone <> 1
    # Bring up menu
    beginPause: "Select option below"
    comment: "Nudge Time and Pitch"
    positive: "time nudge amount", .prevTimeVal
    positive: "pitch nudge amount", .prevPitchVal
    comment: "Relative percent for duration manipulation (100 for no change)"
    positive: "duration percentage", 100
    boolean: "play on apply", .prevPlayCheck
    userOption = endPause: "Exit", "Time -", "Time +", "F0 -", "F0 +","Scale", "Export", 2, 1

    # Look up user choice

    # If user selected "Exit", quit executing the script
    if userOption = 1
      fileDone = 1
    # If user selected a time nudge transformation
    elsif userOption = 2
        @nudge_time: time_nudge_amount*(-1), manObject
    elsif userOption = 3
        @nudge_time: time_nudge_amount, manObject
    # If user selected a pitch nudge transformation
    elsif userOption = 4
        @nudge_pitch: pitch_nudge_amount*(-1), manObject
    elsif userOption = 5
        @nudge_pitch: pitch_nudge_amount, manObject
    # If user specified a duration transformation
    elsif userOption = 6
        @set_duration_points: duration_percentage, manObject
    # If user decides to export files
    elsif userOption = 7
        @export_files: manObject
    endif 

    # If user wants the manipulation to play after the transformation
    if play_on_apply = 1 and userOption <> 7
        selectObject: manObject
        Play (overlap-add)
    endif

    #   fileDone = 1
    #   if doPrev = 1
    #     repeatFile = 1
    #     doPrev = 0
    #   endif
    # If user selected "Prev", proceed back to previous file
    # elsif userOption = 3
    #   fileDone = 1
    #   .ifile = ifile - 2
    #   doPrev = 1
    # endif
    .prevTimeVal = time_nudge_amount
    .prevPitchVal = pitch_nudge_amount
    .prevPlayCheck = play_on_apply
  endwhile
endproc

# Procedure to nudge times earlier or later. There's a praat function
# PitchTier > Modify interval which I think could do the same thing, 
# but the menu isn't very intuitive. 
procedure nudge_time: .nudge, .manObj
    # Identify current manipulation editor
    selectObject: .manObj
    .editorName$ = selected$(1) 
    
    # Get the selection bounds
    editor: .editorName$
        .selectionTimeStart = Get start of selection
        .selectionTimeEnd = Get end of selection
    endeditor

    # Create a new pitch tier to do our shifting with
    .ptObj = Extract pitch tier
    selectObject: .ptObj

    # Get the selected points
    .firstPulse = Get nearest index from time: .selectionTimeStart
    .lastPulse = Get nearest index from time: .selectionTimeEnd
    .nPulses = .lastPulse - .firstPulse + 1

    # Extract the times and pitch values of the selected pulses
    .pulseTimes# = zero# (.nPulses)
    .pulseVals# = zero# (.nPulses)
    selectObject: .ptObj
    for pulsei from .firstPulse to .lastPulse
        .pulseTimes#[pulsei - .firstPulse + 1] = Get time from index: pulsei
        .pulseVals#[pulsei - .firstPulse + 1] = Get value at index: pulsei
    endfor

    # Remove the old points
    selectObject: .ptObj
    Remove points between: .selectionTimeStart - 0.000001, .selectionTimeEnd + 0.000001
    
    # Add the shifted points
    for pulsei from .firstPulse to .lastPulse
        Add point: .pulseTimes#[pulsei - .firstPulse + 1] + .nudge, .pulseVals#[pulsei - .firstPulse + 1]
    endfor

    # Apply transformation to the manipulation
    selectObject: .manObj
    plusObject: .ptObj
    Replace pitch tier

    # Remove our temporary pitch tier
    selectObject: .ptObj
    Remove
endproc

# Preocedure to nudge pitch pulses up/down (in frequency).
# This is pretty easy to do using the manipulation editor's
# menu options, so this wrapper isn't as verbose as for
# the nudge_time procedure
procedure nudge_pitch: .nudge, .manObj
    # Identify current manipulation editor
    selectObject: .manObj
    .editorName$ = selected$(1) 
    
    # Get the selection bounds
    editor: .editorName$
        Shift pitch frequencies: .nudge, "Hertz"
    endeditor
endproc

epsilon = 0.000001
procedure set_duration_points: .wholePercent, .manObj
    .durTo = .wholePercent / 100
    # Identify current manipulation editor
    selectObject: .manObj
    .editorName$ = selected$(1) 
    
    # Get the selection bounds
    editor: .editorName$
        .selectionTimeStart = Get start of selection
        .selectionTimeEnd = Get end of selection
        .selectionOuterStart = .selectionTimeStart - epsilon
        .selectionOuterEnd = .selectionTimeEnd + epsilon

        Select: selectionOuterStart - epsilon, selectionOuterEnd + 2*epsilon
        Remove duration point(s)

        Add duration point at: .selectionOuterStart, 1
        Add duration point at: .selectionOuterEnd, 1
        Add duration point at: .selectionTimeStart, .durTo
        Add duration point at: .selectionTimeEnd, .durTo
    endeditor
endproc

# Helper to save manipulation files
procedure export_files: .manObj
    # Get the file name from the manipulation object name
    selectObject: .manObj
    .manName$ = selected$(1)
    .fileName$ = right$(.manName$, length(.manName$) - 13)

    # Publish the resynthesis and save all the associated manipulation files.
    selectObject: .manObj
    .newSoundObj = Get resynthesis (overlap-add)
    selectObject: .manObj
    .newPtObj = Extract pitch tier
    selectObject: .manObj
    .newDtObj = Extract duration tier

    selectObject: .newSoundObj
    Save as WAV file: outDir$ + .fileName$ + ".wav"

    selectObject: .newPtObj
    Save as text file: outDir$ + .fileName$ + ".PitchTier"

    selectObject: .newDtObj
    Save as text file: outDir$ + .fileName$ + ".DurationTier"

    appendInfoLine: "Saved files for" + .fileName$ + " in " + outDir$ + "!"
endproc

fileDone = 0
writeInfoLine: "Starting manipulation for object #" + string$(manObject)
@annotate_file_gui: 0.01, 10, 0
