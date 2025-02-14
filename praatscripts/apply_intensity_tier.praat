################################################################################
# Make Chains
# Author: Thomas Sostarics
# Created: 12 February 2025
# Last Updated: 14 February 2025
################################################################################
# This script creates concatenated chains for groups of files that share a
# pattern
################################################################################

form Apply intensity tier manipulation
  text fromWavFile ../02_ExtractedRecordings/_retainers/m_damian_dined_long_hlh_250208_001_001.wav
  text toWavFile ../02_ExtractedRecordings/m_damian_dined_long_hll_250208_001_001.wav
  text outWavFile ../02_ExtractedRecordings/m_damian_dined_long_hlh_250208_001_001.wav
  text fromTgFile ../02_ExtractedRecordings/_retainers/m_damian_dined_long_hlh_250208_001_001.TextGrid
  text toTgFile ../02_ExtractedRecordings/Annotated_TextGrids/m_damian_dined_long_hll_250208_001_001.TextGrid
  natural resolution 50
  boolean cleanup 0
endform

fromWavObj = Read from file: fromWavFile$
toWavObj   = Read from file: toWavFile$
fromTgObj  = Read from file: fromTgFile$
toTgObj    = Read from file: toTgFile$

# Create intensity tier objects and relevant timepoints
selectObject: fromWavObj
fromRawIntObj = To Intensity: 50, 0, "no"
fromIntObj = Down to IntensityTier
fromPulseN = Get number of points
fromEndTime = Get time from index: fromPulseN

selectObject: toWavObj
toRawIntObj  = To Intensity: 50, 0, "no"
toIntObj = Down to IntensityTier
toPulseN = Get number of points
toEndTime = Get time from index: toPulseN

# Get the starting time of the last labeled interval in each textgrid
selectObject: fromTgObj
fromInterval = Get number of intervals: 1
fromInterval = fromInterval - 1
fromStartTime = Get start time of interval: 1, fromInterval

selectObject: toTgObj
toInterval = Get number of intervals: 1
toInterval = toInterval - 1
toStartTime = Get start time of interval: 1, toInterval

# Create a new blank IntensityTier and add a point 
# just before the manipulated region with value 1
# (so the preceding region stays the same)
selectObject: toIntObj
newTierObj = Copy: "newTier"
Remove points between: 0, 5
Add point: toStartTime - 0.005, 0.0 

# Extract equally spaced points along the designated interval,
# which in practice will basically time normalize things
fromTimeSeq# = from_to_count#(fromStartTime, fromEndTime, resolution)
toTimeSeq#   = from_to_count#(toStartTime,   toEndTime,   resolution)

# Get the intensity values at each point along the time
# time normalized interval, then compute the multiplicative
# values for the new tier to use for the manipulation
for ipoint from 1 to resolution
  selectObject: fromIntObj
  y = Get value at time: fromTimeSeq#[ipoint]
  
  selectObject: toIntObj
  x = Get value at time: toTimeSeq#[ipoint]

  # Relative decibel transformation will multiply
  # fromIntObj by 10 ^ (db / 20), where db is the
  # difference in decibels (a logarithmic unit)
  dbDifference = y - x
  
  selectObject: newTierObj
  Add point: toTimeSeq#[ipoint], dbDifference
endfor

selectObject: newTierObj
finalTime = toTimeSeq#[resolution] 
Add point: finalTime + 0.005, 0

# Apply the manipulation; Multiply creates a new object
selectObject: toWavObj
plusObject: newTierObj
newWavObj = Multiply: 0
Save as WAV file: outWavFile$

# Remove all the objects used in the script
if cleanup 
 removeObject: fromRawIntObj, fromIntObj, fromWavObj, fromTgObj
 removeObject: toRawIntObj, toIntObj, toWavObj, toTgObj
 removeObject: newTierObj, newWavObj
endif

writeInfoLine: "Saved file to " + outWavFile$

