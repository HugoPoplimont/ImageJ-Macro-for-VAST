//// Co-localization VAST analysis
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
//Part of the macro to split the Leica file into files of 3 images
//drag and drop the image in fiji and then this part of the macro will get the name of the image and the directory of the image and select it
title=getTitle();
path = getDirectory("image");
	selectWindow(title);
//get the dimensions of the image it is important to extract the information about the number of channel to split the images into the proper amount of image
frameNumber=nSlices();
getDimensions(width, height, channels, slices, frames);
//number of channels multiplied by the number of image per fish here it is 3 images of the tail if more or less images of the fish change this number
Numbertodivide=channels*3;
//separate all individual images
divider=frameNumber/Numbertodivide;
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
//Part of the Macro to stitch the 3 images of the tail together based on MAX intensity of channel3 this can be modified but here channel 3 is fliGFP so it is the best channel to base the stitching on
title=getTitle();
path2 = getDirectory("image");
	selectWindow(title);
run("Stack to Hyperstack...", "order=xyczt(default) channels=3 slices=1 frames=3 display=Color");
run("Make Substack...", "channels=1-3 frames=1");
//I save all the splitted individual images of the tail to stitch together
	saveAs("Tiff", path2 + title + "1" + ".tif");
	selectWindow(title);
	run("Make Substack...", "channels=1-3 frames=2");
	saveAs("Tiff", path2 + title + "2" + ".tif");
	selectWindow(title);
	run("Make Substack...", "channels=1-3 frames=3");
	saveAs("Tiff", path2 + title + "3" + ".tif");
selectWindow(title + "1" + ".tif");
	rename("stich1");
selectWindow(title + "2" + ".tif");
	rename("stich2");
selectWindow(title + "3" + ".tif");
	rename("stich3");
// that is the stitching part
run("Pairwise stitching", "first_image=stich1 second_image=stich2 fusion_method=[Max. Intensity] fused_image=stich1<->stich2 check_peaks=100 compute_overlap x=1868.0000 y=140.0000 registration_channel_image_1=[Only channel 3] registration_channel_image_2=[Only channel 3]");
run("Pairwise stitching", "first_image=stich1<->stich2 second_image=stich3 fusion_method=[Max. Intensity] fused_image=stich1<->stich2<->stich3 check_peaks=100 compute_overlap x=1868.0000 y=140.0000 registration_channel_image_1=[Only channel 3] registration_channel_image_2=[Only channel 3]");
//save the file into a new directory automatically created and called analysis
splitDir= path2 + "/Analysis/";
print(splitDir); 
File.makeDirectory(splitDir); 
selectWindow("stich1<->stich2<->stich3");
saveAs("Tiff",  splitDir + title + "stitched" + ".tif"); 
	selectWindow(title + "stitched" + ".tif");
//Homemade colocalisation analysis First I split the channel
run("Split Channels");
//Select channel 3
selectWindow("C3-"+title + "stitched" + ".tif");
//Change contrast of the channel 3 and turn it into a mask
run("Enhance Contrast", "saturated=6.50");
run("Apply LUT");
setOption("BlackBackground", true);
run("Convert to Mask");
//select channel 2 change the contrast and intensity it is also easier to turn it into RGB color to help substract background that create a lot of noise when the image turn into a binary image mask
selectWindow("C2-"+title + "stitched" + ".tif");
setAutoThreshold("RenyiEntropy");
setThreshold(90,65000);
setOption("BlackBackground", true);
run("Convert to Mask");
//Here we want to have the measurements of the area fraction occupied by our masks on the image
run("Set Measurements...", "area_fraction redirect=None decimal=3");
run("Measure");
//Here we substract C3 from C2 to obtain a image that show the cell outside of the blood vessel
imageCalculator("Subtract create", "C2-"+title + "stitched" + ".tif" ,"C3-"+title + "stitched" + ".tif");
selectWindow("Result of C2-"+title + "stitched" + ".tif");
//We measure again the area but here area of the cell outside the blood vessel
run("Measure");
//Now it saves all those masks so we can check them later
selectWindow("C3-"+title + "stitched" + ".tif");
saveAs("Tiff",  path + title + "C3");
selectWindow("C2-"+title + "stitched" + ".tif"); 
saveAs("Tiff",  path + title + "C2"); 
selectWindow("Result of C2-"+title + "stitched" + ".tif");
saveAs("Tiff",  path + title + "C3subC2"); 
close("*");
}
//Next part of the macro is to take all the images, assign them nice colours and write the name of each images on the image itself so we can easily see it
//Apply batch processing so I can apply the same macro to all the images in the folder of stitched images
//get the list of files from this folder
list2 = getFileList(splitDir);
setBatchMode(false);
run("Read and Write Excel", "dataset_label=[Results] no_count_column file=[" + path + "Results" + "_excel.xlsx] sheet=VAST");
//activate batchmode
setBatchMode(true);
//create a loop for all the images in the folder
for (i=0; i<list2.length; i++) {
showProgress(i+1, list2.length);
open(splitDir+list2[i]);
//Change the colour of the channels and annotate each images with its name
title=getTitle();
selectWindow(title);
setFont("SansSerif", 75, " antialiased");
setColor("white");
drawString(title, 234, 143);
Stack.setChannel(1);
run("Grays");
Stack.setChannel(2);
run("Red");
Stack.setChannel(3);
run("Green");
selectWindow(title);
//save the file into a new directory automatically created and called Annotated for annotated images
splitDir2= splitDir + "/Annotated/";
print(splitDir2); 
File.makeDirectory(splitDir2); 
selectWindow(title);
saveAs("Tiff",  splitDir2 + title + "named");
run("Close All");
}