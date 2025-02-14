################################################################################
# Example script for computing H1-H2 (for educational purposes)
# Author: Thomas Sostarics
# Created:      29 May 2024
# Last Updated: 29 May 2024
################################################################################
# Given a loaded sound object's index and a desired timepoint and window width,
# this script will compute H1-H2 for the given window.
# Note that this does not compute the formant-corrected value (aka H1*-H2*).
# If you would like to extend this script to do so, please refer to lines
# 317-369 of the spectralMeasures.praat file from praatSauce:
#
# https://github.com/kirbyj/praatsauce/blob/master/src/spectralMeasures.praat
#
# You should also familiarize yourself with working with procedures in Praat
# if you want to refer to the above script. You'll need to work backwards
# through the code and import procedures like correct_iseli_z.praat.
# You can also refer to the script above to figure out how to include other
# spectral measures like H1-A3.
#
# This script can also be extended to use a textgrid to determine the timepoints
# rather than supplying them manually. 
#
# While this script returns H1-H2 to the info line, this script can be edited
# to write a CSV with the value. I would recommend also writing the following
# information (as columns) to each row (assuming you use an interval tier)
#
#  - Filename: Filename of the sound object
#  - Interval_Index: Index of the interval on the interval tier (unique w/in file)
#  - Interval_Label: Label of the interval (not necessarily unique w/in flie!)
#  - F0: The measured mean F0 within the window in Hertz (F0=H1, 2*F0=H2)
#  - H1mH2: The difference between H1 and H2 in decibels
#
# Warning 1: Pitch halving and doubling can occur, so if F0 looks suspiciously
#            higher or lower than it should be, this may be what's going on.
#            This can also affect H1-H2 measures.
#
# Warning 2: This script is written to use the default settings for filtered
#            autocorrelation to extract F0, which requires Praat version 6.4 or
#            newer. If you want to change the pitch range for the speaker, you
#            will also need to adjust the attenuation factor. Alternatively,
#            you can extract pitch using raw autocorrelation; just change the
#            `To Pitch (filtered ac):` line accordingly. See below:
#
# https://www.fon.hum.uva.nl/praat/manual/How_to_choose_a_pitch_analysis_method.html
# https://www.fon.hum.uva.nl/praat/manual/Sound__To_Pitch__filtered_ac____.html
# https://www.fon.hum.uva.nl/praat/manual/Sound__To_Pitch__raw_ac____.html
# https://www.fon.hum.uva.nl/praat/manual/Ltas.html
# https://www.fon.hum.uva.nl/praat/manual/Spectrum__To_Ltas__1-to-1_.html
################################################################################

form
	integer soundObj 2
	real regionStart 2.614
	real windowWidth 0.100
endform

# Compute the endpoint of the reion of interest
regionEnd = regionStart + windowWidth

# Load a sound, create a pitch object to extract pitch
# without needing to open the sound object itself
selectObject: soundObj
pitchObj = To Pitch (filtered ac): 0, 50, 800, 15, "yes", 0.03, 0.09, 0.5, 0.055, 0.35, 0.14

# Extract f0 from the pitch object
selectObject: pitchObj
f0val = Get mean: regionStart, regionEnd, "Hertz"

# If F0 is not defined in the region, then there's no
# point in computing anything else
if f0val <> undefined
	# Compute f0 range to search for a peak
	f0_pct_diff = f0val * 0.1
	f0min  = f0val - f0_pct_diff
	f0max  = f0val + f0_pct_diff

	# Get f0 for second harmonic (2*f0)
	f0min2 = 2*f0val - f0_pct_diff
	f0max2 = 2*f0val + f0_pct_diff

	# Get the spectrum and ltas objects
	selectObject: soundObj
	soundSelectionObj = Extract part: regionStart, regionEnd, "rectangular", 1, "no"
	spectrumObj       = To Spectrum: "yes"
	ltasObj           = To Ltas (1-to-1)

	# Extract H1 and H2
	h1db = Get maximum: f0min,  f0max,  "none"
	h2db = Get maximum: f0min2, f0max2, "none"
	
	# Compute uncorrected H1-H2
	h1mh2 = h1db - h2db

	# Write H1-H2 value with heuristic interpretation
	voiceDescription$ = ", probably modal!"
	if h1mh2 > 10
		voiceDescription$ = ", maybe breathy!"
	elif h1mh2 < -1
		voiceDescription$ = ", maybe creaky!"
	endif
	
	writeInfoLine: "H1-H2 for selected region: ", 'h1mh2', voiceDescription$
	
	# Cleanup
	selectObject: pitchObj, spectrumObj, soundSelectionObj, ltasObj
	Remove
else
	writeInfoLine: "F0 undefined for selected region"
endif

################################################################################
# Above comments as skeleton pseudocode:
#
# - Compute the endpoint of the reion of interest
# - Load a sound, create a pitch object to extract pitch
#   without needing to open the sound object itself
# - Extract f0 from the pitch object
# - If F0 is not defined in the region, then there's no
#   point in computing anything else
# - if f0 <> undefined:
#   - Compute f0 range to search for a peak
#   - Get f0 for second harmonic (2*f0)
#   - Get the spectrum and ltas objects
#   - Extract H1 and H2
#   - Compute uncorrected H1-H2
#   - Write H1-H2 value with heuristic interpretation
#   - Cleanup
# - else
#   - F0 is undefined, no result
################################################################################