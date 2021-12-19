/*
* _   _  ____  _____   _____ ______   ___    _______     ___   _          __  __ _____ _____
*| \ | |/ __ \|  __ \ / ____|  ____| |__ \  |  __ \ \   / / \ | |   /\   |  \/  |_   _/ ____|
*|  \| | |  | | |__) | (___ | |__       ) | | |  | \ \_/ /|  \| |  /  \  | \  / | | || |
*| . ` | |  | |  _  / \___ \|  __|     / /  | |  | |\   / | . ` | / /\ \ | |\/| | | || |
*| |\  | |__| | | \ \ ____) | |____   / /_  | |__| | | |  | |\  |/ ____ \| |  | |_| || |____
*|_| \_|\____/|_|  \_\_____/|______| |____| |_____/  |_|  |_| \_/_/    \_\_|  |_|_____\_____|
*  ______ _____ _   _______ ______ _____
* |  ____|_   _| | |__   __|  ____|  __ \
* | |__    | | | |    | |  | |__  | |__) |
* |  __|   | | | |    | |  |  __| |  _  /
* | |     _| |_| |____| |  | |____| | \ \
* |_|    |_____|______|_|  |______|_|  \_\
*  Filter a soundfile with the Praat analysis from a list of Norse words.
*  Created by Joe Wright for Edmund Hunt / the Augmented Reality project at
*  Royal Birmingham Conservatoire, UK, 2021
*/
//==============================================================
(
/*
  _____ _______ ______ _____    __
 / ____|__   __|  ____|  __ \  /_ |
| (___    | |  | |__  | |__) |  | |
 \___ \   | |  |  __| |  ___/   | |
 ____) |  | |  | |____| |       | |
|_____/   |_|  |______|_|       |_|
* ENTER WORDS AND PARAMETERS
*/
//Input: Enter words separated by spaces, replacing those within the quotations below.
//These must be spelt correctly and within the archive file, see the
//"WordList.csv" file for reference.
~input = "áðr á dǫggu fǫðurhefnda";
//___________________________________________________________________
//Sound File: add path to your soundfile in between the quotations below
~soundFile = "/copy/soundfile/path/here";
//___________________________________________________________________
//Stretch Duration: A value of 1 plays back at normal speed, 2 will be twice as slow, 0.5 will
//be twice as fast etc. The output is smoother with ~timeStretch values > 1
~timeStretch = 1;
//___________________________________________________________________
//Word Gap: add a gap between each 'word' as the filters are played back. The gap is 0 by default,
//meaning the output is continuous until all words are played.
~wordGap = 0;
//___________________________________________________________________
//Filter Width: the bandwidth in octaves between -3 dB frequencies. A value of 1 gives a fairly
//full-bodied sound, while lower values like 0.01 (default), are more focused around the phoneme
//formants. Smaller values will yield a quieter output.
~filtWidth = 0.01;
//___________________________________________________________________
//Filename prefix for the AugVoc wordbank being used. This should only be changed if/when more
//archive files are added to the project folder. For the current version, this can be left alone.
~wordBank = "NF_Words";
//====================================================================
/*
  _____ _______ ______ _____    ___
 / ____|__   __|  ____|  __ \  |__ \
| (___    | |  | |__  | |__) |    ) |
 \___ \   | |  |  __| |  ___/    / /
 ____) |  | |  | |____| |       / /_
|_____/   |_|  |______|_|      |____|
* EXECUTE THE CODE
*
* Execute the code by pressing cmd+enter (mac) or ctl+enter (win/linux)
* The post window will display the progress of the processing, and the location of the recorded
* soundfile.
*/
//====================================================================
//====================================================================
s.boot;
s.waitForBoot({
	var
	input,
	tempArray,
	words,
	data,
	getFileName,
	getWordData,
	getDataSequence,
	dataSeq,
	source,
	filters,
	audioBus,
	buf,
	cueFilter,
	player;

	//split words in input string by spaces
	input = ~input.split($ );

	//READ WORDS CSV FILE AND REMOVE UNNECESARY BLANK ROWS
	// (this is a workaround for a quirk in the file read object)
	words = CSVFileReader.read(thisProcess.nowExecutingPath.dirname +/+ "/WordList.csv");
	tempArray =  Array.new(words.size/2);
	for(0, words.size, {
		|i|
		if(i%2==0, {
			tempArray.add(words[i][0]);
		});
	});
	words = tempArray;

	//READ ANALYSIS CSV FILE AND REMOVE UNNECESARY BLANK ROWS
	// (this is a workaround for a quirk in the file read object)
	data = CSVFileReader.read(thisProcess.nowExecutingPath.dirname +/+ "/NF_Data.csv");
	tempArray =  Array.new(data.size/2);
	for(0, data.size, {
		|i|
		if(i%2==0, {
			tempArray.add(data[i]);
		});
	});
	data = tempArray;
	//GET FILENAME OF WORD IN ARCHIVE
	//(match the word to it's corresponding file in the archive)
	getFileName = {
		arg key;
		var index, fName;
		i=0;
		fName = ~wordBank ++ "_";
		while( {i < words.size}, {
			if(key==words[i],{
				index=i;
				i=words.size;
			});
			i=i+1;
		});
		for(0, (3 - index.asString.ascii.size), {
			fName = fName ++ "0";
		});
		fName=fName++index.asString++".wav";
	};
	//GET ANALYSIS DATA FOR THE WORD
	//get the Praat analysis data for the soundfile. In the spreadsheet, there
	//can be multiple lines per word, these are collected as an array of arrays.
	getWordData = {
		arg key;
		var done, dataOut;
		dataOut=Array.new(data.size);
		i=0;
		done=0;
		while( {(done<2) && (i<data.size)}, {
			case
			{ (done==(0))&&(data[i][0]==key) }{
				done=1;
				dataOut.add(data[i]);
			}
			{ (done==1)&&(data[i][0]==key) }{
				dataOut.add(data[i]);
			}
			{ (done==1)&&(data[i][0]!=key) }{
				done=2;
			};
			i = i+1;
		});
		dataOut;
	};
	//GET DATA SEQUENCE FOR INPUT WORDS
	//string together data for each word into an overall sequence of values
	getDataSequence = {
		dataSeq=Array.new(data.size);
		for(0, input.size-1, {
			|i|
			dataSeq.add(
				getWordData.value(
					getFileName.value(input[i])
				)
			);
		});
	};
	//Run the data functions above.
	getDataSequence.value();

	//GROUPS / BUFFER / BUS
	source = Group.new;
	filters = Group.after(source);
	audioBus = Bus.audio(s, 1);
	buf = Buffer.readChannel(s, ~soundFile, channels: 0);

	//SYNTHDEFS
	//SOURCE - PLAY SOUND FILE
	SynthDef(\source, {
		var sig;
		sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf), 1, 0, 1);
		// Out.ar(i, sig);
		Out.ar(audioBus, sig);
	}).add;

	//SINGLE BAND PASS FILTER
	SynthDef(\filter, {
		arg freq1, freq2, dur, vol1, vol2;
		var sig, env, env2, freqEnv, fade;
		fade = Clip.kr(dur*0.1, 0.025, 2);
		freqEnv = EnvGen.kr(Env.new([freq1, freq2], [dur+fade]));
		env2 = EnvGen.kr(Env.new([vol1, vol2], [dur+fade]));
		env = EnvGen.kr(Env.new([0,1,1,0], [fade,dur,fade]), doneAction:2);
		sig = In.ar(audioBus, 1);
		sig = BBandPass.ar(sig, freqEnv, ~filtWidth, env*env2);
		sig = Clip.ar(sig, -0.8, 0.8);
		Out.ar(0, sig!2);
	}).add;

	//CUE FILTER
	//decide whether or not to trigger filters
	cueFilter = {
		arg freq1, freq2, dur, vol1, vol2;
		freq1 = freq1.asFloat;
		freq2 = freq2.asFloat;

		if(freq1>0, {
			if(freq2<=0, {freq2=freq1});
			// vol1=vol1.asFloat/100;
			// vol2=vol2.asFloat/100;
			Synth(\filter, [freq1: freq1, freq2: freq2, dur: dur, vol1: vol1, vol2: vol2], filters);
		});
	};
	//PLAYER
	player = Task{
		//wait for synthdefs to load
		3.wait;
		//start recording
		s.record;
		0.5.wait;
		//play soundfile
		Synth(\source, target: source);
		//cue in filters from data sequence...
		//dataSeq os in format dataSeq[wordSeq][wordPhonemes][phonemeData]
		for(0, dataSeq.size-1, { |i|
			for(0, dataSeq[i].size-1, { |j|
				var phSegDur, phData;
				phData = dataSeq[i][j];
				phData[0].post;
				"    ".post;
				phData[1].postln;
				phSegDur = (phData[5].asFloat / 3) * ~timeStretch * 0.001;
				//beginning
				cueFilter.value(phData[2], phData[3], phSegDur, 1,1);//phData[6], phData[7]);
				cueFilter.value(phData[9], phData[10], phSegDur, 1,1);// phData[6], phData[7]);
				cueFilter.value(phData[12], phData[13], phSegDur, 1,1);//, phData[6], phData[7]);
				cueFilter.value(phData[15], phData[16], phSegDur, 1,1);// phData[6], phData[7]);
				cueFilter.value(phData[18], phData[19], phSegDur, 1,1);// phData[6], phData[7]);
				phSegDur.wait;
				//middle
				cueFilter.value(phData[3], phData[4],  phSegDur, 1,1);// phData[7], phData[8]);
				cueFilter.value(phData[10], phData[11], phSegDur, 1,1);// phData[7], phData[8]);
				cueFilter.value(phData[13], phData[14], phSegDur, 1,1);// phData[7], phData[8]);
				cueFilter.value(phData[16], phData[17], phSegDur, 1,1);// phData[7], phData[8]);
				cueFilter.value(phData[19], phData[20], phSegDur, 1,1);// phData[7], phData[8]);
				phSegDur.wait;
				//end
				cueFilter.value(phData[4], phData[4], phSegDur, 1,1);// phData[8], phData[8]);
				cueFilter.value(phData[11], phData[11], phSegDur, 1,1);// phData[8], phData[8]);
				cueFilter.value(phData[14], phData[14], phSegDur, 1,1);// phData[8], phData[8]);
				cueFilter.value(phData[17], phData[17], phSegDur, 1,1);// phData[8], phData[8]);
				cueFilter.value(phData[20], phData[20], phSegDur, 1,1);// phData[8], phData[8]);
				phSegDur.wait;
			});
			~wordGap.wait;
		});
		s.stopRecording;
		"Recording saved to: ".post;
		thisProcess.platform.recordingsDir.postln;
		s.freeAll;
	}.reset.play;
});
);
