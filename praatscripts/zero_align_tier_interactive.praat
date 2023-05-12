# Align all boundaries to zero crossings.
# Intended for interactive use, I don't recommend using this with a shell.
#
# Select a sound object and a corresponding TextGrid object, then provide
# the script with a tier index. The script then creates a new textgrid object
# with "_zeroed" appended to the name. In this new textgrid, all of the boundaries
# on the specified tier will be nudged to the nearest zero crossing with their
# labels retained.
#
# Tip: Click 'apply' instead of 'ok' in the form to avoid rerunning the script.
#      Then you can quickly run the script on multiple textgrids.
#
# Adapted from a script by Danielle Daidone 5/2/17, itself 
# adapted from a script by Jose J. Atria 5/21/12
# https://www.ddaidone.com/uploads/1/0/5/2/105292729/move_left_boundary_left_for_labeled_intervals___zero_cross.txt
#####################################################################################

form Zero align tiers
	comment Specify tier to be processed:
	integer tier 1
endform

# Get currently selected sound and textgrid
soundobj = selected("Sound")
tgobj = selected("TextGrid")
tgname$ = selected$("TextGrid")

# Make a copy of the text grid so we don't have any destructive edits
selectObject: tgobj
Copy: tgname$ + "_zeroed"
tgobj = selected("TextGrid")

selectObject: tgobj

      #check if specified tier is interval tier
      interval = Is interval tier... tier
      
      # Process intervals
      if interval 
         ni = Get number of intervals... tier
         for i to ni
          	label$[i] = Get label of interval... tier i
         endfor
			 # ni-1 since the last boundary would be the right edge, which cant be moved
             for i to ni-1
             selectObject: tgobj
		  
			#move right boundary to closest zero crossing
			boundary = Get end point... tier i
			selectObject: soundobj
			zero = Get nearest zero crossing... 1 boundary
			  if boundary != zero
				selectObject: tgobj
				Remove right boundary... tier i
				Insert boundary... tier zero
			  endif
		    
		  endif
               endfor

        selectObject: tgobj
        for i to ni
          name$ = label$[i]
          Set interval text... tier i 'name$'
        endfor

	selectObject: tgobj

	else
	writeInfoLine: "Specified tier is not an interval tier"
     endif