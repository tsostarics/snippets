# extract_and_save_intervals
# 
#	This script extracts and saves intervals in an independent sound file, the name of files will be the label the intervals have.
#	
#	Wendy Elvira-GarcÃ­a (2015). Extract_and_save_intervals, v.1 [Praat script]
#	wendyelviragarcia@ g m a i l .com
#	Laboratori de FonÃ¨tica. Universitat de Barcelona.
# 	This script is free software under GNU Public License v.3 http://www.gnu.org/copyleft/gpl.html
#
#	Extended functionality by Thomas Sostarics
#	New features: Select which tier to extract; denote a delimeter for filenames
#	eg an interval label of "oranges^Well you know I don't like citrus..." will be extracted as oranges.wav
#	this is useful if intervals have long labels but you don't want to completely overwrite them
#
#########################################################################################################
# 
#					INSTRUCTIONS
#
#	0. Before you start: You need a sound and its matching TextGrid with the intervals you want to extract.
#		SELECT THE SOUND YOU WANT TO ANALYSE
#	1. Open the script (Open/Read from file...), click Run in the upper menu and Run again. 
#	2. Tell the script if you have any label whose intervals you don't want to extract. For example, 
#	don't extract empty intervals, or don't extract intervals where there is a "x" written or a "no".
#	The files will be saved with the same name the interval has, but you can choose a preffix and a suffix that will apply to all files. 
#	For exemple, the code of the speaker as a prefix.
#	3. A folder selector will open select, where do you want to save the new files.
#
#
#########################################################################################################

form Extract_and_save_intervals
	comment Select the Sound you want to extract the intervals from
	comment  
	comment Do you want to extract all interval?
	comment If you don`t write here the label of the intervals you don`t want to extract.
	word do_not_extract ""
	comment If you do not want to extract empty intervals write ""

	word prefix 
	word suffix 

	comment If you want to specify a tier, use its number
	natural tier 1
	
	comment If you want to specify a delimeter, enter it here (write "" if not desired)
	word delim ""
endform

marca_de_silencio$ = do_not_extract$
informante$ = prefix$
repeticion$ = suffix$
folder$ = chooseDirectory$ ("Choose the folder where the sounds will be saved:")
#falta que lo haga del sonido seleccionado
@extract_and_save_intervals: folder$



procedure extract_and_save_intervals: .directoryOutput$
	#.directoryOutput$ = chooseDirectory$: "Choose a directory to save all the new files in"
	if .directoryOutput$ <> ""
		.numberOfSelectedSounds = numberOfSelected ("Sound")
		if .numberOfSelectedSounds = 0
		pause Select the Sound you want to extract from and click OK
		endif
		.base$ = selected$ ("Sound")
		selectObject: "TextGrid " + .base$
		
		#compruebo que el grid sea de ese Sound
		.soundDur = Get total duration
		.gridDur = Get total duration
		if .soundDur<>.gridDur
			El sonido y el TextGrid tienen duraciones diferentes. Â¿Seguro que son del mismo archivo?
		endif
		
		#me apetecia que el margen de los archivos fuera silencio puro, pero para limpiarlos no irÃ¡ bien...
		#selectObject: "Sound " + .base$
		# sampl_frequ = Get sampling frequency
		# silence = Create Sound from formula: "silence", 1, 0, 0.2, sampl_frequ, "0"
		# silence2 = Create Sound from formula: "silence", 1, 0, 0.2, sampl_frequ, "0"
		.numberOfIntervals = Get number of intervals: tier
		for .interval from 1 to .numberOfIntervals
			
			selectObject: "TextGrid " + .base$
			.codigo$ = Get label of interval: tier, .interval
			# If a delim character is set
			#if delim$ <> ""
			#	.codigo$ = left$(.codigo$, (index(.codigo$, delim$)-1))
			#endif
			printline Codigo '.codigo$'
			if .codigo$ <> marca_de_silencio$
				printline Extrayendo intervalo '.interval' '.codigo$'
				.int_start = Get start point: tier, .interval
				.int_end = Get end point: tier, .interval
				selectObject: "Sound " +.base$
				#extraigo los intervalos con un margen porque sino van muy justos, en el caso de que sea el primer sonido o el ÃƒÂºltimo no hay posibilidad de silencio
				if .interval = 1 
					Extract part: .int_start, .int_end+0.2, "rectangular", 1, 0
				elif .interval = .numberOfIntervals
					Extract part: .int_start-0.2, .int_end, "rectangular", 1, 0
				else
					Extract part: .int_start-0.2, .int_end+0.2, "rectangular", 1, 0
				endif
				Save as WAV file: .directoryOutput$ + "/" + informante$ + .codigo$ + repeticion$ +  ".wav"
				Remove
			endif
		endfor
	endif
endproc