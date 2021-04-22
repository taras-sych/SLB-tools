

//----------------------------Input-----------------------------------

time = 10; //time for analysis in minutes
setBatchMode(true);

int_thick = 1; //interface thickness in micrometers
//---------------------------------------------------------------------

flag = 0;
Stack.getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight); 
T = Stack.getFrameInterval();
frames = (time* 60 -(time * 60) % T )/T + 1;

dir = getDirectory("image");

image_list = getList("image.titles");
ni = nImages;

file=File.open(dir+ File.separator + "Results.xls");

frame_counter = 0;

for (im = 0; im < ni; im++) {
	
	
	selectWindow(image_list[im]);
	rename ("raw_data_stack");
run("Smooth", "stack");

run("32-bit");

if (flag == 0){
	waitForUser("Measure Thresholds");
Dialog.create("Input thresholds")

Dialog.addNumber("Bacteria bottom", 350);
Dialog.addNumber("Membrane top", 200);
Dialog.show();

bacteria_bottom=Dialog.getNumber();
bacteria_top=4096;

membrane_bottom=0;
membrane_top=Dialog.getNumber();

flag =1;
}


run("Split Channels");

selectWindow ("C1-raw_data_stack");
rename ("bacteria_stack");

selectWindow ("C2-raw_data_stack");
rename ("membrane_stack");



print ("Image name: " + image_list[im]);
print (file, "Image mame: " + image_list[im]);

for (j=2; j<3; j++){
	linewidth = round(int_thick/pixelWidth);
	print (linewidth);
	
	print ("Line width: " + linewidth);
	print("--------------------------------------------");
	print("--------------------------------------------");
	print(" ");
	
print(file," ");	
print(file, "Line width:" + "\t" + linewidth);
print(file," ");	
print (file, "Time, min" + "\t" + "Total" + "\t" + "Interface" + "\t" + "Ld" + "\t" + "Lo" + "\t\t" + "Area Interface" + "\t" + "Area Ld" + "\t" + "Area Lo" + "\t\t" + "Interface norm" + "\t" + "Ld norm" + "\t" + "Lo norm");

for (index = 1; index < frames+1; index ++){

	print("Frame: " + index);
	print("--------------------------------------------");
	selectWindow("bacteria_stack");
	setSlice(index);
	run("Duplicate...", " ");
	rename ("bacteria");




	selectWindow("membrane_stack");
	setSlice(index);
	run("Duplicate...", " ");
	rename ("membrane");

	selectWindow("bacteria");

	setThreshold(bacteria_bottom, bacteria_top);
	run("Analyze Particles...", "size=10-Infinity pixel show=Masks");
	selectWindow("bacteria");
	close();
	selectWindow("Mask of bacteria");
	rename ("bacteria");

	

	selectWindow("membrane");
	setThreshold(membrane_bottom, membrane_top);
	run("Analyze Particles...", "size=10-Infinity pixel add");

	roi_array = newArray(roiManager("count"));

	for (i = 0; i < roiManager("count"); i++) 
		roi_array[i] = i;

	newImage("Interface", "8-bit black", width, height, 1);


	roiManager("Select", roi_array);
	roiManager("Combine");

	run("Line Width...", "line=linewidth");
	setForegroundColor(255, 255, 255);
	run("Draw", "slice");

	roiManager("deselect");
	run("Select None");

	run("32-bit");
	run("Enhance Contrast...", "saturated=0.3 normalize");

	setAutoThreshold("Default dark");
	//run("Threshold...");

	run("Analyze Particles...", "size=10-Infinity summarize");



	imageCalculator("Multiply create 32-bit", "bacteria","Interface");
	rename("Interface and bacteria");


	selectWindow("Interface");
	setThreshold(0.5, 1);

	roiManager("Deselect");
	roiManager("Delete");

	run("Analyze Particles...", "size=10-Infinity add");
	roi_array = newArray(roiManager("count"));

	for (i = 0; i < roiManager("count"); i++) 
		roi_array[i] = i;

	newImage("Pure_Ld", "8-bit black", width, height, 1);

	roiManager("Select", roi_array);
	roiManager("Combine");

	run("Make Inverse");

	setForegroundColor(255, 255, 255);
	run("Fill", "slice");

		setAutoThreshold("Default dark");
	//run("Threshold...");

	run("Analyze Particles...", "size=10-Infinity summarize");

	roiManager("deselect");
	run("Select None");

	imageCalculator("Multiply create 32-bit", "bacteria","Pure_Ld");
	rename("Pure Ld and bacteria");

	selectWindow("Interface");
	setThreshold(0, 0.5);

	roiManager("Deselect");
	roiManager("Delete");

	run("Analyze Particles...", "size=10-Infinity add exclude");


	newImage("Pure_Lo", "8-bit black", width, height, 1);

	roi_array = newArray(roiManager("count"));

	for (i = 0; i < roiManager("count"); i++) 
		roi_array[i] = i;

	roiManager("Select", roi_array);
	roiManager("Combine");

	setForegroundColor(255, 255, 255);
	run("Fill", "slice");

		setAutoThreshold("Default dark");
	//run("Threshold...");

	run("Analyze Particles...", "size=10-Infinity summarize");

	

	imageCalculator("Multiply create 32-bit", "bacteria","Pure_Lo");
	rename("Pure Lo and bacteria");

	run("Clear Results");

//-----------------------Areas-----------------------------


	selectWindow("Summary");
			lines = split(getInfo(), "\n");
			//headings = split(lines[0], "\t");
			values = split(lines[frame_counter*3 + 1], "\t");
				
			interface_area = parseInt(values[2]) * pixelWidth * pixelHeight;

			values = split(lines[frame_counter*3 + 2], "\t");

			Ld_area = parseInt(values[2]) * pixelWidth * pixelHeight;

			values = split(lines[frame_counter*3 + 3], "\t");

			Lo_area = parseInt(values[2]) * pixelWidth * pixelHeight;

			frame_counter ++;
//---------------------------------------------------------

	selectWindow ("bacteria");
	setThreshold(150, 1000000);
	run("Analyze Particles...", "size=4-Infinity pixel display");

	

	total_bacteria = nResults;
	print ("Total bacteria: " + nResults);

	run("Clear Results");

	selectWindow ("Interface and bacteria");
	setThreshold(150, 1000000);
	run("Analyze Particles...", "size=4-Infinity pixel display");

	interface_count = nResults;
	interface_norm = nResults/interface_area;
	print ("Interface: " + interface_count);
	print ("Interface norm: " + interface_norm);
	run("Clear Results");


	selectWindow ("Pure Ld and bacteria");
	setThreshold(150, 1000000);
	run("Analyze Particles...", "size=4-Infinity pixel display");

	Ld_count = nResults;
	Ld_norm = nResults/Ld_area;
	print ("Pure Ld: " + Ld_count);
	print ("Pure Ld norm: " + Ld_norm);
	run("Clear Results");

	selectWindow ("Pure Lo and bacteria");
	setThreshold(150, 1000000);
	run("Analyze Particles...", "size=4-Infinity pixel display");

	Lo_count = nResults;
	Lo_norm = nResults/Lo_area;
	print ("Pure Lo: " + Lo_count);
	print ("Pure Lo norm: " + Lo_norm);



	
	run("Clear Results");
	print("--------------------------------------------");
	print("--------------------------------------------");
	print(" ");
	

	//------------------------Closing,deleting and saving------------------------------
	selectWindow("Pure Ld and bacteria");
	close();
	selectWindow("Interface and bacteria");
	close();
	selectWindow("Pure Lo and bacteria");
	close();
	selectWindow("Pure_Lo");
	close();
	selectWindow("Interface");
	close();
	selectWindow("Pure_Ld");
	close();
	selectWindow("membrane");
	close();
	selectWindow("membrane_stack");
	selectWindow("bacteria");
	close();
	roiManager("deselect");
	roiManager("delete");
	run("Clear Results");
	
	print (file, (index - 1)*T/60 + 5 + "\t" + total_bacteria + "\t" + interface_count + "\t" + Ld_count + "\t" + Lo_count + "\t\t" + interface_area + "\t" + Ld_area + "\t" + Lo_area + "\t\t" + interface_norm + "\t" + Ld_norm + "\t" + Lo_norm);	
}

print(file," ");	

selectWindow("Log");

print(" ");
print(" ");

}


}
//------


File.close(file);

run("Collect Garbage");

waitForUser("8");


