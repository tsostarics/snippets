##########################################
# Draw pitch continua to EPS file
# Thomas Sostarics: ??/??/2021
# Last Updated: 08/17/2022
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
	comment Enter first and last obj number
	natural startobj 1
	natural endobj 25
	comment Give obj number of textgrid (0 to skip)
	integer tg_obj 26
endform

cur_obj = startobj
set_option$ = "yes"
name$ = "far"
Black
if tg_obj <> 0
	selectObject: tg_obj
	Copy: "blank"
	selectObject: "TextGrid blank"
	nTiers = Get number of tiers
	for i from 1 to nTiers
		Replace interval texts: i, 1, 0, ".*", "", "Regular Expressions"
	endfor

	selectObject: cur_obj
	plusObject: tg_obj
	View & Edit
	editor: tg_obj
		Draw visible pitch contour and TextGrid: set_option$, set_option$, "no", "no", "no", "no", set_option$
	Close
	endeditor
	set_option$ = "no"
	name$ = "no"
	cur_obj = cur_obj + 1
	Red

	while cur_obj <= endobj
		selectObject: cur_obj
		plusObject: "TextGrid blank"
		View & Edit
		editor: "TextGrid blank"
			Draw visible pitch contour and TextGrid: set_option$, set_option$, "no", "no", "no", "no", set_option$
		Close
		endeditor
		cur_obj = cur_obj + 1
	endwhile
else
	while cur_obj <= endobj
		selectObject: cur_obj
		View & Edit
		editor: cur_obj
			Draw visible pitch contour: set_option$, "no", name$, "no", "no", set_option$
		Close
		endeditor
		set_option$ = "no"
		name$ = "no"
		cur_obj = cur_obj + 1
		Red
	endwhile
endif
Black