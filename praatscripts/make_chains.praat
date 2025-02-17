################################################################################
# Make Chains
# Author: Thomas Sostarics
# Created: 12 February 2025
# Last Updated: 14 February 2025
################################################################################
# This script creates concatenated chains for groups of files that share a
# pattern
################################################################################

form Make chains
  text inDir ../03_ResynthesizedRecordings
  text outDir ../Samples
endform

# Clean paths
inDir$ = inDir$ + "/"
outDir$ = outDir$ + "/"


patterns$# = {"hhh", "hhl", "hlh", "hll", "lhh", "lhl", "llh", "lll"}

for i from 1 to size(patterns$#)
  pattern$ = patterns$#[i]
  Create Strings as file list: "list", inDir$ + "*" + pattern$ + "*"
  numberOfFiles = Get number of strings

  objNums# = zero#(numberOfFiles)

  for ifile from 1 to numberOfFiles
    select Strings list
    # Load files from respective directories
    wavFilename$ = Get string: ifile
    wavObj = Read from file: inDir$ + wavFilename$
    objNums#[ifile] = wavObj
  endfor

  selectObject: objNums#[1]
  for iobj from 1 to numberOfFiles
    plusObject: objNums#[iobj]
  endfor

  chainObj = Concatenate
  Rename: pattern$

  Save as WAV file: outDir$ + pattern$ + ".wav"
  select Strings list
  Remove

  selectObject: objNums#[1]
  for iobj from 1 to numberOfFiles
    plusObject: objNums#[iobj]
  endfor
  plusObject: chainObj 

  Remove

endfor

writeInfoLine: "Files saved to " + outDir$