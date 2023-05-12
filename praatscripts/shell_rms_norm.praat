################################
# Shell Version of RMS Norm
# Thomas Sostarics 9/9/2022
#
# RMS Norm all files in directory
# to either the given value
# or to a calculated optimum.
# This script is designed to
# be used from the command line
# and is based on NU's RMS norm
# script.
################################

form RMS Normalization
	comment Directory of sound files with textgrids
	text fromDir ..\altest\input
	comment Directory for output sound files
	text outDir ..\altest\output
	comment Manual RMS value (enter 0 to use calculated optimal value)
	natural rmsVal 70
	comment Check to force clip, unchecked will throw error if clipping detected
	boolean forceClip 0
endform

# Check for final slash
if right$(fromDir$, 1) <> "\"
	fromDir$ = fromDir$ + "\"
endif
if right$(outDir$, 1) <> "\"
	outDir$ = outDir$ + "\"
endif

filenames = Create Strings as file list: "list", fromDir$ + "*.wav"
numberOfFiles = Get number of strings
levels$ = ""
for ifile to numberOfFiles
	select Strings list
	filename$ = Get string: ifile
	
	Read from file: fromDir$ + filename$
	filename$ = left$(filename$, length(filename$)-4)
	objname$ = replace$(filename$, " ", "_", 0)

	selectObject: "Sound " + objname$
	oldRmsLevel = Get root-mean-square: 0, 0
	extremum = Get absolute extremum: 0, 0, "none"
	newLevel = 0.99 * oldRmsLevel / extremum

	selectObject: "Sound " + objname$
	Remove
	
	levels$ = levels$ + "'newLevel'" + ","
endfor

levels$ = left$ (levels$, length(levels$)-1)
minPa = min ('levels$')
minRMS = 20 * log10('minPa'/0.00002)
minRMS = floor('minRMS')

if rmsVal <> 0
	minRMS = rmsVal
endif

new_RMS_level = 0.00002 * 10^(minRMS/20)

for ifile to numberOfFiles
	selectObject: filenames
	filename$ = Get string: ifile
	Read from file: fromDir$ + filename$
	filename$ = left$(filename$, length(filename$)-4)
	objname$ = replace$(filename$, " ", "_", 0)

	selectObject: "Sound " + objname$
	oldRmsLevel = Get root-mean-square: 0, 0
	Formula: "new_RMS_level * self / oldRmsLevel"
	extremum = Get absolute extremum: 0, 0, "none"
	
	if extremum > 0.99
		if forceClip = 1
			exit We refuse to clip the samples in file "'filename$'"
		endif
	endif

	Save as WAV file: outDir$ + objname$ + ".wav"
	selectObject: "Sound " + objname$
	Remove
endfor

select all
Remove