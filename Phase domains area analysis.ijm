/*
+++++++++++++++++++++++++++++++++++++++++++++++++
+  	SLB time lapse analysis software 			+
+	Develloped by Taras Sych					+
+ 	This plug-in is designed to investigate 	+
+	membrane phase mixing and membrane   		+
+ 	disruption induced by lectins on  			+
+	supported lipid bilayers containing		 	+
+	oligosachired bearing glycolipids			+
+												+
+   Version  --- 2017							+
+												+	
+++++++++++++++++++++++++++++++++++++++++++++++++

+
Image recommendation
•	Raw data gray scale image (no scale or color bars)
•	One color channel which represents lipid bilayer membrane
•	Multiple time frames

*/

//requires("1.51p");
ScreenClean();
getDateAndTime(year, month, dayofWeek, dayofMonth, hour, minute, second, msec);

//---------------------------------------Input parameter section--------------------------------------------
//----------------------------------------------------------------------------------------------------------
	
	solidity = 10;			// minimal solidity of Lo domains in percent
	min_detected = 20;		// minimal size of detected particles in pixels
	batch_mode = true;		// batch mode for analysis
	batch_mode_c = false;	// batch mode for correction
	
//----------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------


//-------------------  Select image to process  ------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------
run("Open...");
name = getTitle;
dir = getDirectory("image"); 

Stack.getDimensions(width, height, channels, slices, frames);

run ("32-bit");
if (channels > 1 || slices > 1)
	Select_raw_data();

Stack.getDimensions(width, height, channels, slices, frames);




dir = dir + " " + year +"." + month + "." + dayofMonth + " " + hour + "." + minute +" - " + name + "\\" ;
File.makeDirectory(dir);
//----------------------------------------------------------------------------------------------------------


//-------------------  Bleaching correction  ------------------------------------------------------------
	//--------------------------------------------------------------------------------------------------------
	if (getBoolean("Bleaching correction?") == 1){
	rename ("raw data");
	run ("32-bit");

	waitForUser( "slect area","select area");

	run("Duplicate...", "title=crop duplicate");
	//run("Plot Z-axis Profile");
	Stack.getDimensions(width, height, channels, slices, frames);
	bleach_coef = newArray (frames);

	for (i=0; i<frames; i++){
		setSlice(i+1);

		run("Set Measurements...", "mean redirect=None decimal=3");
		run("Measure");
	
		bleach_coef [i] = getResult ("Mean",0);
		run("Clear Results");
	}

	selectWindow("crop");
	close();

	selectWindow("raw data");
	run("Select None");
	setSlice(1);

	run("Duplicate...", "duplicate range=1-1");
	v=bleach_coef [0];
	run("Divide...", "value=v");

	rename ("raw_data_bl_corr");
	
	
	for (i = 1; i<frames; i++){
		j=i+1;
		selectWindow("raw data");
		setSlice(i+1);
		run("Duplicate...", "duplicate range=j-j");
		v=bleach_coef [i];
		run("Divide...", "value=v");
		rename ("tail");
		run("Concatenate...", "  title=raw_data_bl_corr image1=raw_data_bl_corr image2=tail image3=[-- None --]");
	
	}
	}




if (getBoolean("Laser profile correction?") == 1){

// ==========================================================================================================
// **************************     Laser profile correction section      *************************************
// ==========================================================================================================

	//setBatchMode (batch_mode_c);
	dir1 = dir + File.separator + "Correction\\";
	File.makeDirectory(dir1);

	
	//-------------------  Create laser profiles  ------------------------------------------------------------
	//--------------------------------------------------------------------------------------------------------



	rename("raw_data_corrected");

	run("Duplicate...", "title=laser_profile duplicate");

	Stack.getDimensions(width3, height3, channels3, slices3, frames3);

	width3 = minOf(width3, height3);

	width3 = width3/4 - width3%4;

	run("Subtract Background...", "rolling=width3 light create sliding stack");

	imageCalculator("Divide create 32-bit stack", "raw_data_corrected","laser_profile");

	file = dir1 + File.separator +"laser_profile";
	selectWindow("laser_profile");
	saveAs("Tiff", file);
	
	file = dir1 + File.separator + "raw_data_corrected";
	selectWindow("Result of raw_data_corrected");
	saveAs("Tiff", file);

	
	
	ScreenCleanButCurrent();
	rename("raw_data_corrected");

	//--------------------------------------------------------------------------------------------------------
// ==========================================================================================================
// ***********************     End of laser profile correction section     **********************************
// ==========================================================================================================
}

waitForUser( "Threshold for analysis","Measure threshold parameters for analysis");

// ==========================================================================================================
// *********************************    Time lapse analysis     *********************************************
// ==========================================================================================================

//------Array for domain names---
domain_name = newArray(4);
domain_name[0] = "rapture"; 
domain_name[1] = "pure Lo"; 
domain_name[2] = "pure Ld"; 
domain_name[3] = "double layer"; 

legend = "";
//--------------------------------



//------------------------------------dialog Window---------
setBatchMode(batch_mode);

Dialog.create("Input parameters");
Dialog.addCheckbox("rapture", true);
Dialog.addNumber("bottom threshold", 0);
Dialog.addNumber("top threshold", 0.85);


Dialog.addCheckbox("pure Lo", true);
Dialog.addNumber("bottom threshold", 0.85);
Dialog.addNumber("top threshold", 0.95);


Dialog.addCheckbox("pure Ld", true);
Dialog.addNumber("bottom threshold", 0.95);
Dialog.addNumber("top threshold", 1.1);


Dialog.addCheckbox("double layer", true);
Dialog.addNumber("bottom threshold", 1.1);
Dialog.addNumber("top threshold", 3);



Dialog.show();

domain_array = newArray(4);
bottom_array = newArray(4);
top_array = newArray(4);
color_array = newArray("Red", "Blue", "Green", "Cyan");


for (i=0; i<4; i++){
	domain_array[i] = Dialog.getCheckbox();
	bottom_array[i] = Dialog.getNumber();
	top_array[i] = Dialog.getNumber();
	
}
//--------------------------------------


dir = dir + File.separator + "Analysis\\";
File.makeDirectory(dir);

//-------------------------Output of file with input parameters

file = File.open(dir+"/"+"parameters.txt");

print(file,"solidity = " + solidity);
print(file," ");
print(file,"domain" + "\t\t" + "bottom"+"\t\t"+ "top");
		
for(i=0;i<4;i++){
			
	print(file,domain_name[i] + "\t\t" + bottom_array[i]+"\t\t" + top_array[i]);
}
File.close(file);

//-----------------------------------Rename and smooth
rename("raw_data_corrected");

//run("Smooth", "stack");

//-------------------------------------------------------
number_of_previous_frames = 0;

Stack.getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight); 

//------Slices <=> Frames--------------------------------------------
if (slices>frames){
	run("Properties...", "slices=frames frames=slices ");
	Stack.getDimensions(width, height, channels, slices, frames);
}
//--------------------------------------------------------------------


//-----------------Initialization of output arrays

total_area = newArray (frames);
area_percentage = newArray (frames);


Plot.create("Percentage of phases", "Frame", "%Area");
Plot.setLimits (0,frames,0,100);
//----------------------------------------------------------------------------


for (dom=0; dom<domain_array.length; dom++){

	if (domain_array[dom] == true){
		selectWindow("raw_data_corrected");

		type = domain_array[dom];
		bottom=bottom_array[dom];
		top=top_array[dom];

		



		for (number_of_frame=1; number_of_frame<=frames; number_of_frame++){
//---------------Deletion of stuff-------------------------------
	run("Clear Results");

	if (roiManager("count") > 0){
		roiManager("Delete");
	}

//---------------Processing of all patterns except Lo-------------------
			if (dom != 1){
				selectWindow("raw_data_corrected");
				setSlice(number_of_frame);

				run("Duplicate...", "title=mask");


				setAutoThreshold("Default dark");
				//run("Threshold...");

				setThreshold(bottom, top);


				run("Set Measurements...", "area mean min redirect=None decimal=3");

				run("Analyze Particles...", "size=min_detected-Infinity pixel  show=Masks display   clear summarize add in_situ");
				run("Invert LUT");
				run(color_array[dom]);

				run("32-bit");
				}

				
//------------------------------------------Processing of Lo
			if (dom == 1){

//-----------------------------------------mask include--------------------------------------
				selectWindow("raw_data_corrected");
				setSlice(number_of_frame);

				run("Duplicate...", "title=mask");


				setAutoThreshold("Default dark");
				//run("Threshold...");

				setThreshold(bottom, top);

				run("Set Measurements...", "area area_fraction mean min centroid  redirect=None decimal=3");

				run("Analyze Particles...", "size=min_detected-Infinity pixel  show=Masks display clear  add in_situ");
				run("Invert LUT");
				run(color_array[dom]);

				run("32-bit");

				rename ("Mask_exclude");

				run("Clear Results");

				if (roiManager("count") > 0){
					roiManager("Delete");
				}
//-----------------------------------------mask exclude--------------------------------------
				selectWindow("raw_data_corrected");
				setSlice(number_of_frame);

				run("Duplicate...", "title=mask");


				setAutoThreshold("Default dark");
				//run("Threshold...");

				setThreshold(bottom, top);

				run("Set Measurements...", "area area_fraction mean min centroid  redirect=None decimal=3");

				run("Analyze Particles...", "size=min_detected-Infinity pixel  show=Masks display clear include add in_situ");
				run("Invert LUT");
				run(color_array[dom]);

				run("32-bit");

				rename ("Mask_include");
				close();
//------------------------Deletion of fake Lo----------------------------
				selectWindow ("Mask_exclude");
				for (i = 0; i<roiManager("count"); i++){
	
					sol = getResult ("%Area", i);
					roiManager ("Select", i);
					nameROI = Roi.getName;
					row = nameROI + " " + sol;
					//print (row);
					if (sol > solidity){
						//roiManager("Select", i);
						//run("Clear", "slice");
						roiManager("Delete");
						IJ.deleteRows(i, i);
						i=-1;
						}
				}
				
//------------------------Analysis of remaining patterns-----------
				//selectWindow ("corrected_mask");
				run("Select None");

				for (i = 0; i<roiManager("count"); i++){
					roiManager("Select", i);

					run("Clear", "slice");
					}

				run("Select None");

				setThreshold(129.0000, 255.0000);

				run("Set Measurements...", "area mean min centroid  redirect=None decimal=3");
				run("Analyze Particles...", "size=min_detected-Infinity pixel  show=Masks display  clear summarize add in_situ");
				run("Invert LUT");
				run(color_array[dom]);

				run("32-bit");

			}




//---------------------------------------------------------------------
//}}}
//--------------------------Stack of masks--------------------------
			name = "mask_for_frame_" + number_of_frame + "_threshold_" + bottom +"_" + top;
			rename(name);
			if (number_of_frame == 1){
				rename ("stack_of_masks");
			}

			if (number_of_frame > 1){ 
				rename("stack_temp");
				run("Concatenate...", "  title=[stack_of_masks] image1=stack_of_masks image2=stack_temp image3=[-- None --]");
			}



//----------------------------Getting Summary data------------

			selectWindow("Summary");
			lines = split(getInfo(), "\n");
			//headings = split(lines[0], "\t");
			values = split(lines[number_of_frame + number_of_previous_frames], "\t");
				
			total_area [number_of_frame-1] = parseInt(values[2]) * pixelWidth * pixelHeight;

			area_percentage [number_of_frame-1] = values[4];

//----------------------------plot and save distribution of area

			dir2 = dir + File.separator + "Data for distributions\\";
			File.makeDirectory(dir2);
			
			xld=File.open(dir2+ File.separator+"Lo domains frame" + number_of_frame + ".xls");

			print(xld,"domain area in pixels");

			for (jj = 0; jj<nResults; jj++){
	
				print(xld,getResult ("Area", jj));	
	
			}

			File.close(xld);
//--------------------------------------------------------------

			run("Clear Results");

			if (roiManager("count") > 0){
				roiManager("Delete");
			}
//}


//----------------------------------------------------------------------------------



		}

		run("Merge Channels...", "c2=raw_data_corrected c3=stack_of_masks create keep");
		run("Properties...", "channels=2 slices=1 frames=frames unit=unit pixel_width=pixelWidth pixel_height=pixelHeight voxel_depth=1.0000000 frame=[20.07 sec]");

		selectWindow("Merged");
		run("RGB Color", "frames");


//--------------------------output in file--------------------------
		file = File.open(dir+"/"+domain_name[dom]+".txt");

		print(file,"frame" + "\t\t" + "Total area"+"\t\t"+ "%_Area");
		
		for(i=0;i<frames;i++){
			
			print(file,i+1 + "\t\t" + total_area[i]+"\t\t"+area_percentage[i]);
		}
		File.close(file);

//------------------------------------Rename and save current results

		name1 = "merged_" + domain_name[dom] + ".tif";
		selectWindow("Merged");
		rename(name1);
		file1 = dir + "/" + name1;
		saveAs("Tiff", file1);
		close();
		
		name2 = "stack_of_masks_" + domain_name[dom] + ".tif";
		selectWindow("stack_of_masks");
		rename(name2);
		file2 = dir + "/" + name2;
		saveAs("Tiff", file2);
		close();

		







		number_of_previous_frames = number_of_previous_frames + frames;

		
//-----------------------------------Plotting---
		Plot.setColor (color_array[dom]);
		Plot.add ("Lines",area_percentage);
		//Plot.setLegend("label1\tfff", "top-right");
		legend = legend + domain_name[dom] + "\t";
	}
}

ScreenClean();
setBatchMode (false);

Plot.setLegend(legend, "top-right");
Plot.show();


Plot.makeHighResolution("Percentage of phases_HiRes",4.0);

selectWindow("Percentage of phases");
close();



// ==========================================================================================================
// *****************************     End of time lapse analysis     *****************************************
// ==========================================================================================================



// ==========================================================================================================
// ***********************************            Functions         *****************************************
// ==========================================================================================================

//---------------Clean screen from all opened windows------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
function Select_raw_data(){
	Stack.getDimensions(width, height, channels, slices, frames);

	Dialog.create("Select raw data");
	if (channels > 1){

		arr_chan=newArray(1);
			arr_chan[0]=1;
		for (i=1; i<channels; i++){
			string1 = i+1;
			arr_chan = Array.concat (arr_chan,string1);
		}	
		
		Dialog.addMessage("Select channel to process");
		Dialog.addChoice("channel", arr_chan);
		
	}

	if (slices > 1){
		
		Dialog.addRadioButtonGroup("Slices",newArray("There are no slices, those are frames","Use first slice"), 2, 1,"There are no slices, those are frames");
	}
	
	Dialog.show();
	
	
	if (channels > 1){
		choice_chan = Dialog.getChoice();
		run("Duplicate...", "title=[raw data] duplicate channels=choice_chan");
	}
	

	if (slices > 1 ){
		slice_op= Dialog.getRadioButton();
		if (slice_op == "There are no slices, those are frames"){
			
			run("Properties...", "slices=frames frames=slices ");
			rename ("raw data");
		}
	}
	
	selectWindow ("raw data");
	close("\\Others");
}

//---------------------------------------------------------------------------------------------------------


//---------------Clean screen from all opened windows------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
function ScreenClean(){
		
	while (nImages>0) close();

          WinOp=getList("window.titles");
	for(i=0; i<WinOp.length; i++)
	  {selectWindow(WinOp[i]);run ("Close");}

	  fenetres=newArray("B&C","Channels","Threshold");
	for(i=0;i!=fenetres.length;i++)
	   if (isOpen(fenetres[i]))
	    {selectWindow(fenetres[i]);run("Close");}
       }
//---------------------------------------------------------------------------------------------------------

//---------------Clean screen from all opened windows------------------------------------------------------
//---------------------------------------------------------------------------------------------------------
function ScreenCleanButCurrent(){
		
	close("\\Others");

          WinOp=getList("window.titles");
	for(i=0; i<WinOp.length; i++)
	  {selectWindow(WinOp[i]);run ("Close");}

	  fenetres=newArray("B&C","Channels","Threshold");
	for(i=0;i!=fenetres.length;i++)
	   if (isOpen(fenetres[i]))
	    {selectWindow(fenetres[i]);run("Close");}
       }
//---------------------------------------------------------------------------------------------------------
