##########################################
# Draw pitch continua to EPS file
# Thomas Sostarics: 08/29/2021
# Last Updated: 08/29/2022
##########################################
# This script draws the pitch contour for
# all files between the given object IDs
# with the associated TextGrid. 
# You will need to load all sound files and
# one TextGrid file before running this.
# Take note of the object IDs in the object
# window and provide these to the script.
# The first iteration of this script will 
# draw the first contour in Black and all 
# others afterwards will be in red. After 
# saving the EPS file from the picture 
# window, you should open the file in 
# illustrator and do the following steps:
#  - Move the compound paths out of
#   the black group
#  - Lock the black group, select all
#    of the red boundaries in the 
#    textgrid area on the bottom
#  - Select all the compound paths
#    (= the pitch contours) and
#    use the eyedropper to take
#    the appearance of the first
#    iteration's pitch contour
#  - Select>Object>All Text Objects
#    and change font to Charis SIL
#  - Manually check and replace the
#    labels in the textgrid
##########################################

form Draw multiple files
	comment Enter filepath for txt file containing files to read
	text filesAt shellDraw_files.txt
	comment Path for textgrid to use
	text tgFile ../altest/output/TextGrids/branning_01_HLL_002_1_1.TextGrid
	comment Output file path (.eps file)
	text outFile ../Figures/praat.eps
	comment Tier to remove (enter 0 to not remove any tier, can only remove 1 tier)
	integer removeTier 3
	comment Enter width and height of praat picture window
	positive width 6
	positive height 4
endform

# Set picture size
Select outer viewport: 0, width, 0, height 

# Load in file paths from text file
files = Read Strings from raw text file: filesAt$
stringsObj = selected("Strings")
numberOfFiles = Get number of strings

# Load the textgrid to use
Read from file: tgFile$
tgObj = selected("TextGrid")

# Remove tier if needed
if removeTier <> 0
	Remove tier: removeTier
endif

# Create a blank version of the textgrid by removing all text from each tier
selectObject: tgObj
Copy: "blank"
blankObj = selected("TextGrid")
selectObject: blankObj
nTiers = Get number of tiers
for i from 1 to nTiers
	Replace interval texts: i, 1, 0, ".*", "", "Regular Expressions"
endfor

# Set starting arguments for drawing the first black drawing with text
whichTg = tgObj
selectObject: tgObj
tgName$ = "TextGrid " + selected$("TextGrid")
set_option$ = "yes"
name$ = "far"
Black
for ifile from 1 to numberOfFiles
	# Load the file to draw
	selectObject: stringsObj
	filepath$ = Get string: ifile
	Read from file: filepath$
	curSoundObj = selected("Sound")

	# Select the sound and appropriate textgrid, draw with textgrid
	selectObject: curSoundObj
	plusObject: whichTg
	View & Edit
	editor: tgName$
		Draw visible pitch contour and TextGrid: set_option$, set_option$, "no", "no", "no", "no", set_option$
	Close
	endeditor

	# Set options for subsequent iterations
	set_option$ = "no"
	name$ = "no"
	Red
	whichTg = blankObj
	tgName$ = "TextGrid blank"
endfor

# Save file
#Save as PDF file: "test.pdf"
Save as fontless EPS file (SILIPA): outFile$
select all
Remove
Quit