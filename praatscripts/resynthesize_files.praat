################################################################################
# Resynthesize files with saved pitch tiers
# Author: Thomas Sostarics
# Created: 2 July 2023
# Last Updated: 9 July 2023
################################################################################
# This script loads pitch tiers held in `inPtDir` and resynthesizes any matching
# files in `inSoundDir` using the pitch pulses in the pitch tier. The output
# wav files are saved in `outDir`. Note that only files with pitch tiers in
# the pitch tier directory will be resynthesized. For example:
# ~/
# ├─ inSoundDir/
# │  ├─ audio_a1.wav
# │  ├─ audio_a2.wav
# │  ├─ audio_b.wav
# ├─ inPtDir/
# │  ├─ audio_a1.PitchTier
# │  ├─ audio_b.PitchTier 
# ├─ outDir/
# │  ├─ audio_a1.wav
# │  ├─ audio_b.wav 
################################################################################
form Resynthesize all files
	comment Directory of input sound files
	text inSoundDir ../02_PossibleRecordings
	comment Directory of input pitchtier files
	text inPtDir ../02_PossibleRecordings/ResynthPitchTiers3
	comment Directory of output sound files and textgrids
	text outDir ../02_PossibleRecordings/ResynthesizedRecordings3
  comment Please enter the pitch range and timesteps for the manipulation
    natural minPitch 40
    natural maxPitch 200
    real timeStep 0.1
endform

# Clean paths
inSoundDir$ = inSoundDir$ + "/"
inPtDir$ = inPtDir$ + "/"
outDir$ = outDir$ + "/"

# Only do resynthesis for files we have resynthesized pitchtiers for
Create Strings as file list: "list", inPtDir$ + "*.PitchTier"
numberOfFiles = Get number of strings


for ifile to numberOfFiles
  select Strings list
  # Load files from respective directories
  ptFilename$ = Get string: ifile
  wavFilename$ = left$(ptFilename$, length(ptFilename$)-9) + "wav"
  wavObj = Read from file: inSoundDir$ + wavFilename$
  ptObj = Read from file: inPtDir$ + ptFilename$

  selectObject: wavObj
  # In place modification
  Scale peak: 0.99
  Scale intensity: 70

  # Create manipulation for the resynthesis
  manObj = To Manipulation: timeStep, minPitch, maxPitch
  
  selectObject: manObj
  plusObject: ptObj
  Replace pitch tier

  selectObject: manObj
  newSoundObj = Get resynthesis (overlap-add)

  # Save resynthesized file
  selectObject: newSoundObj
  Save as WAV file: outDir$ + wavFilename$

  # Clean up objects
  selectObject: newSoundObj
  plusObject: manObj
  plusObject: wavObj
  plusObject: ptObj
  Remove
endfor

writeInfoLine: "Resynthesized " + string$(ifile) + " files!"