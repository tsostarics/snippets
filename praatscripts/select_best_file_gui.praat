################################################################################
# GUI for for selecting best source file for resynthesis
# Author: Thomas Sostarics
# Created: 17 Jul7 2023
# Last Updated: 20 July 2023
################################################################################
# This script loads audio files and pitchtier files, resynthesizes all of the
# audio files, then creates two chains: one of the original wav files and one
# of the resynthesized ones. Two editor windows are opened for both chains.
#
# The task here is to do listen to each resynthesized file and compare to the
# original recordings to decide which source file yields the best-sounding
# resynthesis. In R, a preliminary selection is made based on the turning point
# annotations I've made. Specifically, the file with the lowest sum of the squared
# deviations from the average turning point locations is selected. But this may not
# actually be the best file to use, hence this script. A new CSV file is saved after
# making a selection for each utterance. A floating menu is provided to cycle through
# the files. The options:
# [Exit] Quits the script, does not save current file
# [Next] Updates the output CSV file with the current selection, moves to next file
# [Prev] Updates the output CSV file with the current selection, moves to previous file
#
# The preliminary selection will be marked with an X on the second tier of the
# raw audio chain's textgrid. To select a file, whether it's different or not,
# place an "a" on the label. If your selection is the same as the preliminary 
# selection, having the label be "Xa" is also fine. Capitalization doesn't matter.
#
# If `inCSV` and `outCSV` are the same file, then you can skip previously checked
# recordings. The file will be updated and overwritten accordingly. If the two
# files are not the same and outCSV already exists, you will receive a warning
# before the script attempts to overwrite the file. If you don't want to 
# overwrite the existing output file, select "Exit" and change the output
# file name.
#
# This script was written for a particular workflow in mind (tone annotation)
# but can be modified as needed.
################################################################################

form Select best file from many resyntheses
	comment CSV file to read from
	text inCSV ../checked_selected_files.csv
    comment CSV file to read to (if same as inCSV, input file will be modified!)
    text outCSV ../checked_selected_files.csv
	comment Directory of input raw audio files
	text inSoundDir ../02_PossibleRecordings
    comment Input directory of pitchtiers for resynthesis
    text inPtDir ../02_PossibleRecordings/ResynthPitchTiers3
	comment Should files already done be skipped?
	boolean skipCompleted 1
endform

# Clean paths
inSoundDir$ = inSoundDir$ + "/"
inPtDir$ = inPtDir$ + "/"

# If the output file already exists and is not the same as the
# input file, it WILL be overwritten and progress can be lost.
# This will warn the user and give them a chance to exit.
abortScript = 0
shouldWarn = fileReadable(outCSV$) and (outCSV$ <> inCSV$)
if shouldWarn = 1
    beginPause: "Output file already exists and will be overwritten, press Exit to quit or Continue to overwrite"
    userOption = endPause: "Exit", "Continue", 2, 1
    if userOption = 1
     abortScript = 1
    endif
endif

# https://github.com/kirbyj/praatdet/blob/master/splitstring.praat
procedure splitstring: .string$, .sep$
    .strLen = 0
    repeat
        .sepIndex = index (.string$, .sep$)
        if .sepIndex <> 0
            .value$ = left$ (.string$, .sepIndex - 1)
            .string$ = mid$ (.string$, .sepIndex + 1, 10000)
        else
            .value$ = .string$
        endif
        .strLen = .strLen + 1
        .array$[.strLen] = .value$
    until .sepIndex = 0
endproc

# Helper to do the resynthesis for many files
procedure resynthesize: .wavObj, .newPtObj
    selectObject: .wavObj
    .manObj =  To Manipulation: 0.01, 40, 200
    selectObject: .manObj
    plusObject: .newPtObj
    Replace pitch tier
    selectObject: .manObj
    .newWavObj = Get resynthesis (overlap-add)
    selectObject: .manObj
    Remove

    selectObject: .wavObj
    Scale peak: 0.99
    Scale intensity: 70.0

    selectObject: .newWavObj
    Scale peak: 0.99
    Scale intensity: 70.0
endproc

# Helper to determine what the selected file is
procedure find_selected_file: .tgObj
    selectObject: .tgObj
    .numberOfIntervals = Get number of intervals: 2
    .foundSelection = 0
    .selectedFile$ = ""
    for i from 1 to .numberOfIntervals
        .curLabel$ = Get label of interval: 2, i
        .isSelected = index_regex(.curLabel$, "[aA]")
        .isDefault = index_regex(.curLabel$, "X")

        # Check if the current interval is selected (has an A)
        # If so, set selected file
        if .isSelected <> 0
            .selectedFile$ = Get label of interval: 1, i
        endif
         
        # Check if the current interval is the default
        if .isDefault <> 0
            .defaultFile$ = Get label of interval: 1, i
        endif
    endfor

    # If we haven't set selected file already, then the user did not
    # mark anything with an A, so go with the default file
    if .selectedFile$ = ""
        .selectedFile$ = .defaultFile$
    endif
endproc

# Helper to get the index of the selected interval
procedure find_preselected_index: .tgObj, .selectedFile$
    selectObject: .tgObj
    .numberOfIntervals = Get number of intervals: 2
    for i from 1 to .numberOfIntervals
        .curLabel$ = Get label of interval: 1, i
        .isSelected = .curLabel$ = .selectedFile$
        if .isSelected = 1
            .selectedInterval = i
        endif
    endfor
endproc

# After getting the chain text grids, this adds a tier for
# making your selection
procedure add_tier: .tgObj, .preSelectedFile$, .hasBeenChecked
    selectObject: .tgObj
    Duplicate tier: 1, 2, "selection"
    Replace interval texts: 2, 1, 0, ".", "", "Regular Expressions"
    @find_preselected_index: .tgObj, .preSelectedFile$

    if .hasBeenChecked = 1
        .mark$ = "XX"
    else
        .mark$ = "X"
    endif

    selectObject: .tgObj
    Set interval text: 2, find_preselected_index.selectedInterval, .mark$
endproc

# Helper to update the table object with the new selected file
procedure set_selected_file: .tgObj, .tableObj, .rowNumber
    @find_selected_file: .tgObj
    selectObject: .tableObj
    Set string value: .rowNumber, "newSelectedFile", find_selected_file.selectedFile$
endproc

# Concatenate multiple files
procedure multi_concat: .wavObjs#, .chainName$
    .numberOfObjs = size(.wavObjs#)
    selectObject: .wavObjs#[1]
    for i from 1 to .numberOfObjs
        plusObject: .wavObjs#[i]
    endfor
    .concatObjs# = Concatenate recoverably
    .chainSoundObj = .concatObjs#[1]
    .chainTgObj = .concatObjs#[2]

    selectObject: .chainSoundObj
    Rename: .chainName$

    selectObject: .chainTgObj
    Rename: .chainName$
endproc

# Helper to open a chain and save the editor name for it
procedure open_chain: .chainSound, .chainTg
    selectObject: .chainTg
    .editorName$ = selected$(1)
    plusObject: .chainSound
    View & Edit
endproc

# Main helper to load a bunch of files and pitchtiers then resynthesize them
procedure load_and_resynth_files: .tableObj, .rowNumber
    selectObject: .tableObj
    .allFileString$ = Get value: .rowNumber, "allFiles"
    .preSelectedFile$ = Get value: .rowNumber, "newSelectedFile"
    .hasBeenChecked = 1
    if .preSelectedFile$ = ""
        .preSelectedFile$ = Get value: .rowNumber, "selectedFile"
        .hasBeenChecked = 0
    endif

    # Split by ; to get all the files we need to load
    @splitstring: .allFileString$, ";"
    .ptObjs# = zero#(splitstring.strLen)
    .wavObjs# = zero#(splitstring.strLen)
    .resynthObjs# = zero#(splitstring.strLen)

    # Open each wav file and pitchtier file, then resynthesize
    for i from 1 to splitstring.strLen
        .fileName$ = splitstring.array$[i]
        .ptObjs#[i] = Read from file: inPtDir$ + .fileName$ + ".PitchTier"
        .wavObjs#[i] = Read from file: inSoundDir$ + .fileName$ + ".wav"
        @resynthesize: .wavObjs#[i], .ptObjs#[i]
        .resynthObjs#[i] = resynthesize.newWavObj
    endfor

    # Concatenate raw files into a chain
    @multi_concat: .wavObjs#, "rawChain"
    .rawChainSound = multi_concat.chainSoundObj
    .rawChainTg = multi_concat.chainTgObj
    @add_tier: .rawChainTg, .preSelectedFile$, .hasBeenChecked

    # Concatenate resynthesized files into a chain
    @multi_concat: .resynthObjs#, "resynthChain"
    .resynthChainSound = multi_concat.chainSoundObj
    .resynthChainTg = multi_concat.chainTgObj

    # Open the chains for editing
    @open_chain: .rawChainSound, .rawChainTg
    .rawEditor$ = open_chain.editorName$
    @open_chain: .resynthChainSound, .resynthChainTg
    .resynthEditor$ = open_chain.editorName$

endproc

# This is the main procedure that loads a pause form
# with various buttons. 
procedure annotate_file_gui:
    .ifile = ifile
  while fileDone <> 1
    # Bring up menu
    beginPause: "Select option below"
    userOption = endPause: "Exit", "Next", "Prev", 2, 1

    # Look up user choice

    # If user selected "Exit", quit executing the script
    if userOption = 1
      fileDone = 1
      abortScript = 1
    # If user selected "Next", proceed to next file
    elsif userOption = 2
      fileDone = 1
      if doPrev = 1
        repeatFile = 1
        doPrev = 0
      endif
    # If user selected "Prev", proceed back to previous file
    elsif userOption = 3
      fileDone = 1
      .ifile = ifile - 2
      doPrev = 1
    endif
  endwhile
endproc

# Load the CSV file and get total number of items
tableObj = Read Table from comma-separated file: inCSV$
numberOfFiles = Get number of rows

# At start of script, skip all the files that already have duration tiers
# in the output directory
startFile = 0
if skipCompleted
repeat
  startFile = startFile + 1
  select tableObj
  selectedFileName$ = Get value: startFile, "newSelectedFile"

  alreadyDone = selectedFileName$ <> ""
until alreadyDone = 0 or startFile = numberOfFiles
else
 startFile = 1
endif


# Set starting values for flags
alreadyDone = 0
fileDone = 0
doPrev = 0
repeatFile = 0
alreadyAnnotated = 0
nDoneFiles = 0


writeInfoLine: "Skipping " + string$(startFile-1 ) + " files"

for ifile from startFile to numberOfFiles
 if abortScript = 0
  @load_and_resynth_files: tableObj, ifile  
    repeatFile = 0

    @annotate_file_gui

    if abortScript = 0
    # When we return from the annotation procedure, 
    # close the editor windows
    editor: load_and_resynth_files.rawEditor$
    Close
    editor: load_and_resynth_files.resynthEditor$
    Close

    # Set the new value in the table
    @set_selected_file: load_and_resynth_files.rawChainTg, tableObj, ifile
    ifile = annotate_file_gui.ifile
    # Update CSV file
    selectObject: tableObj
    Save as comma-separated file: outCSV$

    # Clean up objects
    selectObject: load_and_resynth_files.ptObjs#
    plusObject: load_and_resynth_files.wavObjs#
    plusObject: load_and_resynth_files.resynthObjs#
    plusObject: load_and_resynth_files.rawChainSound
    plusObject: load_and_resynth_files.rawChainTg
    plusObject: load_and_resynth_files.resynthChainSound
    plusObject: load_and_resynth_files.resynthChainTg
    Remove
  endif
 # Reset flags
  fileDone = 0
  nDoneFiles = ifile
 endif
endfor

selectObject: tableObj
Remove

appendInfoLine: "Total files complete so far: " + string$(nDoneFiles) + " / " + string$(numberOfFiles) + "(" + left$(string$(nDoneFiles/numberOfFiles*100), 4) + "%)"
appendInfoLine: "You annotated " + string$(nDoneFiles - startFile) + " files this session, good job!"