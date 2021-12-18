(
//enter words separated by commas
~input = "áðr á";
//Filename prefix for the AugVoc wordbank being used
~wordBank = "NF_Words";
)


(
var input, tempArray, words, data, getFileName, getWordData, getDataSequence;
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

getDataSequence = {
	var dataOut;
	dataOut=Array.new(data.size);
	for(0, input.size-1, {
		|i|
		dataOut.add(
			getWordData.value(
				getFileName.value(input[i])
			)
		);
	});
	dataOut;
};

getDataSequence.value();
)

