###################################################################
# Draw pitch contours for a directory of wave files
# Thomas Sostarics 
# Created: 13 Dec 2023
# Last updated: 4 June 2024
#
# This script draws pitch contours for a directory of wave files.
# This script is intended to be used to identify the pitch range 
# of a speaker by enabling the user to quickly find doubling/halving 
# errors via visual inspection.
# 
# Tips: Start with a large pitch range such as [60, 600] and draw
#       all of a speaker's files. Then, narrow the pitch range from there.
#       Sometime's it's helpful to listen to a few speakers' files first.
#
# Form parameters:
#   wavDir$: The directory containing the wav files
#   minPitch: The minimum pitch to use for the manipulation object that extracts the pitch
#   maxPitch: The maximum pitch to use for the manipulation object that extracts the pitch
#   useFilteredAc: Check to use filtered autocorrelation instead of raw autocorrelation.
#                  NOTE that the attenuation factor is set to the default!
#   draw_option$: Whether to use speckles or lines. Default speckles.
#                 Lines can be useful to identify single-sample jumps
#
###################################################################
form
    comment Enter the directory containing the wav files
    text wavDir C:\Users\Thomas\OneDrive - Northwestern University\_FromNUBox\Research\Dissertation\Part1\MidPhonVoiceQuality\03_ExtractedTakes
    comment Enter the pitch range to draw with
    real minPitch 60
    real maxPitch 300
    comment Check to use filtered autocorrelation (not raw)
    boolean useFilteredAc 0
    choice Draw_option 1
      button speckles
      button lines
endform

# Clean directory path
wavDir$ = wavDir$ + "/"

# Get list of files
Create Strings as file list: "list", wavDir$ + "*" + ".wav"
select Strings list
nFiles = Get number of strings

# Drawing settings
garnish$ = "yes"
Erase all
Black

# Draw pitch contours one by one
for ifile to nFiles
    select Strings list
    wavFile$ = Get string: ifile
    # If the microphone malfunctioned and the recording is empty, skip it
    wavObj = nocheck Read from file: wavDir$ + wavFile$
    if wavObj <> undefined
    # If you don't want the contours to be drawn one by one,
    # change "= To" to "= noprogress To"
    #manObj =  To Manipulation: 0.01, minPitch, maxPitch
    #ptObj = Extract pitch tier
    if useFilteredAc = 1
      pObj = To Pitch (filtered ac): 0, 'minPitch', 'maxPitch', 15, 0, 0.03, 0.09, 0.50, 0.055, 0.35, 0.14	
    else
      pObj = To Pitch (raw ac): 0, 'minPitch', 'maxPitch', 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14
    endif
    selectObject: pObj 
    ptObj = Down to PitchTier
    Draw: 0, 0, minPitch, maxPitch, garnish$, draw_option$
    garnish$ = "no"


    #selectObject: wavObj, manObj, ptObj
    selectObject: wavObj, pObj, ptObj
    Remove
    endif
endfor

# Draw horizontal lines at 50 Hz intervals
# to quickly identify bounds of pitch range
Cyan
currentColor$ = "Cyan"
bottomLine = 50
while bottomLine < maxPitch
 Draw line: 0, bottomLine, 3.5, bottomLine
 bottomLine = bottomLine + 50
 if currentColor$ = "Cyan"
   currentColor$ = "Blue"
   Blue
 else
   currentColor$ = "Cyan"
   Cyan
 endif
endwhile

select Strings list
Remove