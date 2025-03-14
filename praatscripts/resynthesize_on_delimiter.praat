################################################################################
# Resynthesize 1 file to multiple files by delimiter
# Author: Thomas Sostarics
# Created: 2 July 2023
# Last Updated: 11 February 2025
################################################################################
# This script resynthesizes an audio file to one or more new files given an
# arbitrary number of PitchTier files that share the same name as the wav file
# but contain an extra delimited field to denote the new resynthesis shape. 
# See example below:
# ~/
# ├─ inSoundDir/
# │  ├─ audio_a1.wav
# │  ├─ audio_a2.wav
# │  ├─ audio_b.wav
# ├─ inPtDir/
# │  ├─ audio_a1_X.PitchTier
# │  ├─ audio_a1_Y.PitchTier
# │  ├─ audio_b_X.PitchTier 
# ├─ outDir/
# │  ├─ audio_a1_X.wav
# │  ├─ audio_a1_Y.wav
# │  ├─ audio_b_X.wav 
################################################################################

form Resynthesize all files
	comment Directory of input sound files
	text inSoundDir ../02_ExtractedRecordings
	comment Directory containing resynthesis pitch tiers
	text inPtDir ../02_ExtractedRecordings/Resynthesis_Pitchtiers
	comment Directory of output sound files and textgrids
	text outDir ../03_ResynthesizedRecordings
  comment Enter file pattern (write *.PitchTier to process all files)
  text filePattern *.PitchTier
  comment Please enter the pitch range and timesteps for the manipulation
    natural minPitch 50
    natural maxPitch 300
    real timeStep 0.01
endform

# Clean paths
inSoundDir$ = inSoundDir$ + "/"
inPtDir$ = inPtDir$ + "/"
outDir$ = outDir$ + "/"

# Only do resynthesis for files we have resynthesized pitchtiers for
Create Strings as file list: "list", inPtDir$ + filePattern$
numberOfFiles = Get number of strings

for ifile to numberOfFiles
  select Strings list
  # Load files from respective directories
  ptFilename$ = Get string: ifile

  #                                       | lastSeparatorIndex
  #                                       v | 10chars |
  # m_damian_dined_long_hhl_250208_001_001_c.PitchTier
  lastSeparatorIndex = rindex_regex(ptFilename$, "_")
  patternWidth = length(ptFilename$) - lastSeparatorIndex - 10
  patternName$ = mid$(ptFilename$, lastSeparatorIndex+1, patternWidth)
  wavFilename$ = left$(ptFilename$, lastSeparatorIndex-1) 
  wavObj = Read from file: inSoundDir$ + wavFilename$ + ".wav"
  ptObj = Read from file: inPtDir$ + ptFilename$

  selectObject: wavObj
  # In place modification
  Scale intensity: 70  
  Scale peak: 0.99
  
  # Create manipulation for the resynthesis
  manObj = To Manipulation: timeStep, minPitch, maxPitch
  
  selectObject: manObj
  plusObject: ptObj
  Replace pitch tier

  selectObject: manObj
  newSoundObj = Get resynthesis (overlap-add)

  # Save resynthesized file
  selectObject: newSoundObj
  Save as WAV file: outDir$ + wavFilename$ + "_" + patternName$ + ".wav"

  # Clean up objects
  selectObject: newSoundObj
  plusObject: manObj
  plusObject: wavObj
  plusObject: ptObj
  Remove
endfor

writeInfoLine: "Resynthesized " + string$(ifile-1) + " files!"