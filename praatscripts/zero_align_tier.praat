###################################################################
# Align all interval tier boundaries to zero crossings
# Thomas Sostarics 
# Created: 31 Oct 2023
# Last updated: 26 Nov 2023
#
# Given a directory of textgrids with a corresponding directory of
# wav files, move all interval boundaries and points on the given tiers
# to their nearest zero crossing.
#
# Form parameters:
#   inSoundDir$: Input directory with wav files
#   inTgDir$: Input directory with textgrid files
#   outTgDir$: Output directory to save aligned textgrid files
#   tiersToProcess$: Space-delimited integer indices for the 
#                    interval tiers you want to align
#   filePattern$: Pattern used to process either all textgrids
#                 in a directory or just those that match a more
#                 specific pattern
#
###################################################################
# Notes
#
# Adapted from a script by Danielle Daidone 5/2/17, itself 
# adapted from a script by Jose J. Atria 5/21/12
# https://www.ddaidone.com/uploads/1/0/5/2/105292729/move_left_boundary_left_for_labeled_intervals___zero_cross.txt
###################################################################

form Zero align tiers
	comment Input sound and textgrid directory. Only sound files with textgrids will be opened.
	text inSoundDir ../02_ExtractedRecordings
	text inTgDir ../02_ExtractedRecordings/Annotated_Textgrids
	comment Output textgrid directory. If it's the same as the input directory, all files will be overwritten.
	text outTgDir ../02_ExtractedRecordings/Zero
	comment Specify tiers to be processed, separated by SPACES:
	text tiersToProcess 1 2
	comment Process tiers matching this pattern (leave as *.TextGrid to process all textgrids)
	text filePattern *.TextGrid
endform

inSoundDir$ = inSoundDir$ + "/"
inTgDir$ = inTgDir$ + "/"
outTgDir$ = outTgDir$ + "/"

tiers$# = splitByWhitespace$#(tiersToProcess$)
n_tiers = size(tiers$#)
Create Strings as file list: "list", inTgDir$ + filePattern$
numberOfFiles = Get number of strings


# Procedure to align intervals on a tier to the nearest zero crossing
procedure align_interval_tier: .tgObj, .tierNum
	# Save all the interval labels so we can re-set them later
	.ni = Get number of intervals... .tierNum
	for i to .ni
		 .label$[i] = Get label of interval... .tierNum i
	endfor

	# ni-1 since the last boundary would be the right edge, which cant be moved
	for i to .ni-1
		selectObject: .tgobj
	
	#move right boundary to closest zero crossing
	.boundary = Get end point... .tierNum i
	selectObject: soundobj
	.zero = Get nearest zero crossing... 1 .boundary
		if .boundary != .zero
		selectObject: tgobj
		Remove right boundary... .tierNum i
		Insert boundary... .tierNum .zero
		endif
	endfor

	# Re-set the interval albels	
	selectObject: .tgobj
	for i to .ni
	  .name$ = .label$[i]
	  Set interval text... tier i '.name$'
	endfor
endproc

# Procedure to align points on a point tier to the nearest zero crossing
procedure align_point_tier: .tgObj, .tierNum
	# Save all the point labels so we can re-set them later
	.ni = Get number of points... .tierNum
	for i to .ni
		 .label$[i] = Get label of point... .tierNum i
	endfor

	# Go through each point
	for i to .ni
		selectObject: .tgobj
	
		# Move point to nearest zero crossing
		.boundary = Get time of point... .tierNum i
		selectObject: soundobj
		.zero = Get nearest zero crossing... 1 .boundary
		if .boundary != .zero
			selectObject: tgobj
			Remove point... .tierNum i
			Insert point... .tierNum .zero
		endif
	endfor

	# Re-set the point labels
	selectObject: .tgobj
	for i to .ni
	  .name$ = .label$[i]
	  Set point text... tier i '.name$'
	endfor
endproc

for ifile to numberOfFiles
	# Load the textgrid and its corresponding sound grid (will throw an error if it doesn't exist)
	select Strings list
	tgFilename$ = Get string: ifile
	wavFilename$ =  left$(tgFilename$, length(tgFilename$)-8) + "wav"
	soundobj = Read from file: inSoundDir$ + wavFilename$
	tgobj_old = Read from file: inTgDir$ + tgFilename$
	selectObject: tgobj_old
	tgname$ = selected$("TextGrid")


	# Make a copy of the text grid so we don't have any destructive edits
	selectObject: tgobj_old
	Copy: tgname$ + "_zeroed"
	tgobj = selected("TextGrid")


	# Go through all the tiers specified by the user
	for tier_i to n_tiers
		tier = number(tiers$#[tier_i])
		selectObject: tgobj

		#check if specified tier is interval tier
		interval = Is interval tier... tier
		
		# Process intervals or points as applicable
		if interval 
			@align_interval_tier: tgobj, tier
		else
			@align_point_tier: tgobj, tier
		endif
	endfor

	# Save the new textgrid and clean up
	selectObject: tgobj
	Save as text file: outTgDir$ + tgFilename$
	selectObject: soundobj
	plusObject: tgobj_old
	plusObject: tgobj
	Remove
endfor

select Strings list
Remove
