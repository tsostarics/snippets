#######################################
# Thomas Sostarics 10/8/2020
# Northwestern University
# tsostarics at northwestern dot edu
#
# Concatenate prefixed sound files
#
#######################################
# Concatenates all files in a directory
# that have the same prefix, export
# the concatenated file into the same
# directory with suffix _c (for concat)
#######################################
#             Instructions
# 1) Select directory with input files
# 2) Select desire output directory
# 3) Enter delimeter character in file
#    names. _ is the default. Eg:
#	oranges_pre_1.wav
#	oranges_pre_2.wav
#	oranges_pre_3.wav
#    the group prefix is "oranges" and
#    the delimeter character is _
# 2) Run, files saved like:
#	oranges_c.wav
######################################

form Concatenate sound files
	comment Directory of input sound files
	text Sound_directory C:\Users\temp
	comment Directory of output sound files
	text out_directory C:\Users\temp
	comment Enter delimeter character (underscore by default)
	text Delim _
	comment Enter suffix character (_c by default)
	text suffix _c
endform

# Double check directory to make sure it ends in a slash
# Note: max and linux users might need to change \ to /
if right$(sound_directory$, 1) <> "\"
	sound_directory$ = sound_directory$ + "\"
endif
if right$(out_directory$, 1) <> "\"
	out_directory$ = out_directory$ + "\"
endif

# Here, you make a listing of all the sound files in the specified directory.

Create Strings as file list: "list", sound_directory$ + "*.wav"
numberOfFiles = Get number of strings

# I've run into trouble using "" so i set an unlikely value
# (it means 'empty space')
priorGrp$ = "KUUHAKU"

for ifile to numberOfFiles
	select Strings list
	filename$ = Get string: ifile
	grp$ = left$(filename$, index(filename$, delim$)-1)
	if grp$ = priorGrp$
		Read from file: sound_directory$ + filename$
		if ifile = numberOfFiles
			select all
			minus Strings list
			Concatenate
			Write to WAV file: out_directory$ + priorGrp$ + suffix$ + ".wav"
			select all
			minus Strings list
			Remove
		endif
	elsif priorGrp$ = "KUUHAKU"
		Read from file: sound_directory$ + filename$
		priorGrp$ = grp$
	elsif grp$ <> priorGrp$
		select all
		minus Strings list
		Concatenate
		Write to WAV file: out_directory$ + priorGrp$ + suffix$ + ".wav"
		select all
		minus Strings list
		Remove
		Read from file: sound_directory$ + filename$
		priorGrp$ = grp$
	endif
endfor

select all
Remove