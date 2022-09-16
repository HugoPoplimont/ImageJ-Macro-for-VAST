//// Co-localization Operetta analysis
//// Automated analysis of cell colocalisation
//// Version 1
//// Hugo Poplimont
//// Requires 
//// -ImageJ v. 1.53d or later
//// -"ResultsToExcel" Plugin
////
////
//Message to indicate that an image has to be open and selected for analysis
while(true) {
	if(nImages == 0) {
		//Dialog - Asks user to choose an image file to open if one is not currently open.
		Dialog.create("Open an Image Series");
		Dialog.addMessage("Please select an image series for analysis");
		Dialog.addFile("", "");
		Dialog.show();

		open(Dialog.getString());
	}
	else break;
}
title=getTitle();
path = getDirectory("image");
	selectWindow(title);
//get the dimensions of the image it is important to extract the information about the number of channel to split the images into the proper number of images
frameNumber=nSlices();
getDimensions(width, height, channels, slices, frames);
//number of channels multiplied by the number of image per fish
Numbertodivide=channels;
//separate all individual images
divider=frameNumber/Numbertodivide;
makeRectangle(1080, 206, 1080, 674);
run("Crop");
run("Stack Splitter" , "number=divider");
	close(title);
	// Create a New directory inside the main directory called Splitimages to save those split images
Dir1 = path + "/Splitimages/";
File.makeDirectory(Dir1); 
//Loop to add increment numbers to image name
for (i=0;i<nImages;i++) {
        selectImage(i+1);
        title = getTitle;
        print(title);
        saveAs("tiff", Dir1+title);
} 
run("Close All");
//Apply batch processing so I can apply the same macro to all the images in the same folder
//get the list of files from this folder
list = getFileList(Dir1);
//activate batchmode
setBatchMode(true);
//create a loop for all the images in the folder to be processed the same way
for (i=0; i<list.length; i++) {
showProgress(i+1, list.length);
open(Dir1+list[i]);
//Thresholding of the image
title=getTitle();
selectWindow(title);        
run("Stack to Hyperstack...", "order=xyczt(default) channels=3 slices=1 frames=1 display=Color");
run("Make Substack...", "channels=1-3 frames=1");
selectWindow(title);
run("Split Channels");
//Thresholding of channel C1 which is the red channel (cancer cells)
selectWindow("C1-"+title);
setAutoThreshold("Yen dark");
//run("Threshold...");
//setThreshold(113, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
//Here we want to have the measurements of the area fraction occupied by our masks on the image
run("Set Measurements...", "area_fraction redirect=None decimal=3");
run("Measure");
//Thresholding of channel C2 which is the green channel (fli GFP)
selectWindow("C2-"+title);
setAutoThreshold("Triangle dark");
//setThreshold(8, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
//Here we substract C1 from C1 to obtain a image that show the cell outside of the blood vessel
imageCalculator("Subtract create", "C1-"+title ,"C2-"+title);
selectWindow("Result of C1-"+title);
//We measure again the area but here area of the cell outside the blood vessel
run("Measure");
//Now it saves all those masks so we can check them later
selectWindow("C1-"+title);
saveAs("Tiff",  path + title + "C1");
selectWindow("C2-"+title); 
saveAs("Tiff",  path + title + "C2"); 
selectWindow("Result of C1-"+title);
saveAs("Tiff",  path + title + "C1subC2"); 
close("*");
}
//save results in excel file
list2 = getFileList(Dir1);
setBatchMode(false);
run("Read and Write Excel", "dataset_label=[Results] no_count_column file=[" + path + "Results" + "_excel.xlsx] sheet=VAST");
run("Close All");