waitForUser("Measure Thresholds");
Dialog.create("Input thresholds")

Dialog.addNumber("Individual bacteria", 300);
Dialog.addNumber("Bacteria cluster", 1000);

Dialog.show();

bacteria=Dialog.getNumber();
cluster=Dialog.getNumber();


dir = getDirectory("Select folder for results");

setBatchMode(true);

image_list = getList("image.titles");

n = nImages;


Stack.getDimensions(width, height, channels, slices, frames);
T = Stack.getFrameInterval();



for (i = 0; i < n; i++) {

	selectWindow(image_list[i]);
	rename ("raw_data");
	run("Split Channels");

	selectWindow("C2-raw_data");
	close();

	selectWindow("C1-raw_data");
	
	run("Smooth", "stack");
	run("Smooth", "stack");
	name = "bacteria_series_" + i+1;

	rename(name);
}





//file=File.open(dir+ File.separator + "Results.xls");

//print (file, "Time, min" + "\t" + "Total" + "\t" + "Min" + "\t" + "Max" + "\t" + "Mean" + "\t" + "StD");

for (frame_number=1; frame_number<frames+1; frame_number++){
	sum_arr = newArray;
	for (image_number = 0; image_number<n; image_number++){
		name = "bacteria_series_" + image_number+1;
		selectWindow(name);
		//frame_number = 73;
		setSlice(frame_number);

		run("Duplicate...", " ");
		rename("Frame_cluster");
		setThreshold(bacteria, 10000000);
		setOption("BlackBackground", false);
		run("Make Binary");

	


		selectWindow("Frame_cluster");
	
		setThreshold(150, 255);
		run("Set Measurements...", "area redirect=None decimal=3");
		run("Analyze Particles...", "size=20-Infinity pixel display");	
	

		arr = newArray(nResults);
	
	
		for (i = 0; i < nResults; i++){
			arr[i] = getResult("Area", i);
		
		}

		

/*
	print("Clusters:" + nResults);
	print("Min:" + min);
	print("Max:" + max);
	print("Mean:" + mean);
	print("StD:" + std);*/


		
		run("Clear Results");
		selectWindow("Frame_cluster");
		close();
		
		}

		sum_arr = Array.concat(arr,sum_arr);
		Array.getStatistics(sum_arr, min, max, mean, std);
		//print (file, (frame_number - 1)*T/60  + "\t" + nResults + "\t" + min + "\t" + max + "\t" + mean + "\t" + std);

		filename_1 = "Array_frame_" + frame_number+1 + ".xls";
		file_1=File.open(dir+ File.separator + filename_1);

	

		for (k=0; k<sum_arr.length; k++){
			print(file_1, sum_arr[k]);
		}
		

		File.close(file_1);
		
}


for (i = 0; i < n; i++) {
	name = "bacteria_series_" + i+1;
	selectWindow(name);
	close();
}
//File.close(file);
waitForUser("8");
