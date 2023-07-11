# script for opening files quickly
form Open resynthesis and make chains
	comment Which word to open
	text wordSelection adequate
	comment Directory of original sound files, then resynthesized files
	text sourceAudioDir ../02_PossibleRecordings
	text resynthAudioDir ../02_PossibleRecordings/ResynthesizedRecordings3
	comment Directory of textgrids
	text tgDir ../02_PossibleRecordings/AnnotatedTextgrids
endform

sourceAudioDir$ = sourceAudioDir$ + "/"
resynthAudioDir$ = resynthAudioDir$ + "/"
tgDir$ = tgDir$ + "/"

# Only look up files we have resyntheses for
fileList = Create Strings as file list: "list", resynthAudioDir$ + "/*" + wordSelection$ + "*.wav"
numberOfFiles = Get number of strings

procedure load_chain: .stringObj, .dir$, .chainName$
	for ifile to numberOfFiles
		selectObject: .stringObj
		filename$ = Get string: ifile
		wavObj = Read from file: .dir$ + filename$
	endfor

	objStart = wavObj - numberOfFiles +1
	selectObject: wavObj

	for i from objStart to wavObj
		plusObject: i
	endfor

	chainObj# = Concatenate recoverably
	for i from 1 to 2
	selectObject: chainObj#[i]
	Rename: .chainName$
	endfor
endproc

writeInfoLine: fileList
@load_chain: fileList, sourceAudioDir$, "source_chain"
@load_chain: fileList, resynthAudioDir$, "resynth_chain"