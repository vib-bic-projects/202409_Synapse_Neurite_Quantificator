// @ File(label="File directory", style="directory") dir
// @ File(label="ROI directory", style="directory") roi_dir

// @String (visibility=MESSAGE, value="Parameters for synapse segmentation", required=false) msg1
// @Integer (label="Channel containing the neurite marker", min=1, max=4, value=4) neurite_channel
// @Integer (label="Channel containing the presynaptic marker", min=1, max=4, value=3) presyn_channel
// @Integer (label="Maximum size filter for segmented presynaptic vesicles [px^2]", min=0, max=200, value=80) maxsize
// @Integer (label="Minimum size filter for segmented presynaptic vesicle [px^2]", min=0, max=200, value= 10) minsize
// @Integer (label="Intensity filter for Presynaptic marker", min=0, max=65535, value=80) presyn_int
// @Integer (label="Maximum distance from presynaptic vesicle surface to neurite [µm]", min=0, max=200, value=0) maxdist

// @ String (label="Draw ROIs manually", choices={"yes", "no"}, style="listBox") drawing

// @String (visibility=MESSAGE, value="Parameters for plaque segmentation", required=false) msg2
// @ String (label="Plaque distance analysis", choices={"yes", "no"}, style="listBox") plaque_analysis
// @Integer (label="Channel containing the plaques marker", min=1, max=5, value=1) plaque_channel
// @Integer (label="Minimum size filter for plaques [µm^2]", min=0, max=200, value= 1) plaque_area
// @Integer (label="Intensity filter for plaque segmentation", min=0, max=65535, value=1000) plaque_thresh


// @ String (label="File suffix", choices={".nd2", ".tif"}, style="listBox") suffix


/* 6/12/2023
About this script
This script takes a 2D multi-channel image and uses one channel to detect cell nuclei and another one containing blob signals inside the nucleus and detects the blobs and quantifies
their area.

MIT License

Copyright (c) Nicolas Peredo
VIB BioImaging Core Leuven - Center for Brain and Disease Research
Nikon Center of Excellence
Campus Gasthuisberg - ON5 - room 04.367
Herestraat 49 - box 62
3000 Leuven
Belgium
phone +32 (0)16/37.70.03

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

When you publish data analyzed with this script please add the references of the used plug-ins:

Legland, D., Arganda-Carreras, I., & Andrey, P. (2016). MorphoLibJ: integrated library and plugins for mathematical morphology with ImageJ. Bioinformatics, 32(22), 3532–3534. doi:10.1093/bioinformatics/btw413
*/

//Get directories and lists of files
setOption("ExpandableArrays", true);
//Blood vessel directory
fileList = getFilesList(dir, suffix);
Array.sort(fileList);
//Tissue volume directory
roiList = getFilesList(roi_dir, ".zip");
Array.sort(roiList);

//Create the different folders with results
File.makeDirectory(dir + "/Analysis");
File.makeDirectory(dir + "/Segmented");
File.makeDirectory(dir + "/Analysis/Synapses");
File.makeDirectory(dir + "/Analysis/Neurites");

for (files = 0; files < fileList.length; files++) {
//for (files = 0; files < 1; files++) {
	
	//File and ROI names
	file = fileList[files];
	name = getBasename(file, suffix);
	
	//Open image
	run("Bio-Formats Importer", "open=[" + dir + File.separator + file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");

	//Open ROI
	if (drawing == "no") {
		roi_file = roiList[files];
		roiManager("Open", roi_dir  + File.separator + roi_file);
	}
	
	//Rename raw image
	run("Z Project...", "projection=[Average Intensity]");
	rename("Raw_Image");
	
	//Neurite image
	/*
	run("Duplicate...", "duplicate channels=" + neurite_channel + "-" + neurite_channel);
	rename("Neurite_Raw");
	*/
	
	//Neurite drawing
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pixelWidth, pixelHeight);
	
	//Creating the calibrated skeleton image
	newImage("Skeleton", "8-bit black", width, height, 1);
	Stack.setXUnit("micron");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=" + pixelWidth + " pixel_height=" + pixelWidth + " voxel_depth=1.0000000");
	
	//Enhance the contrast of the channels of interest for the drawing
	selectWindow("Raw_Image");
	Stack.setChannel(neurite_channel);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(presyn_channel);
	run("Enhance Contrast", "saturated=0.35");
	
	//Small script to show only the neurite and presyn channels from the raw image
	Stack.setDisplayMode("composite");
	
	order_zero = newArray(0, 0, 0, 0);
	order_zero[neurite_channel - 1] = "1";
	order_zero[presyn_channel - 1] = "1";
	order_corrected = String.join(order_zero, "");
	Stack.setActiveChannels(order_corrected);
	
	
	if (drawing == "yes") {
		//Let the user draw the skeleton lines
		setTool("freeline");
		roiManager("Show All");
		waitForUser("Drawing the skeleton", "Please draw the skeleton using the freehand line and add it to the ROI Manager");
	}
	
	////////////////////////////////////////////////////////////////////////////////////////
	/*Section that takes care of labelling each new neurite as a single element and then
	calculate the number of synapses per branch*/
	selectWindow("Skeleton");
	roiManager("show all");
	roiManager("Draw");
	
	//Generate distance image to the neurite
	selectWindow("Skeleton");	/*Section that takes care of labelling each new neurite as a single element and then
	calculate the number of synapses per branch*/
	selectWindow("Skeleton");
	roiManager("show all");
	roiManager("Draw");
	run("Distance Transform 3D");
	rename("Skeleton_distance");
	
	//Pre-synaptic marker image
	//Object segmentation and size filtering
	selectWindow("Raw_Image");
	run("Duplicate...", "duplicate channels=" + presyn_channel + "-" + presyn_channel); // In the case of Jacqueline 
	rename("Presyn_raw");
	
	//Generate presyn vesicle labelled image
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'Presyn_raw', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.1', 'nmsThresh':'0.3', 'outputType':'Label Image', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	run("Label Size Filtering", "operation=Lower_Than_Or_Equal size=[maxsize]");
	run("Label Size Filtering", "operation=Greater_Than_Or_Equal size=[minsize]");
	run("Remap Labels");
	run("32-bit"); //This is necessary because there is a bug in morpholibj whe quantifying intensities using a labelled image of 16-bits
	resetMinAndMax();//necessary to update the labels check this step
	//Reassign pixel size since the generated filtered image is not calibrated anymore
	Stack.setXUnit("micron");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=" + pixelWidth + " pixel_height=" + pixelWidth + " voxel_depth=1.0000000");
	rename("Presyn_labels");
	
	//Measuring intensities in raw signal image and neurite binary for later filtering
	run("Intensity Measurements 2D/3D", "input=Presyn_raw labels=Presyn_labels mean");
	selectWindow("Presyn_raw-intensity-measurements");
	presyn_intensity = Table.getColumn("Mean");
	
	run("Intensity Measurements 2D/3D", "input=Skeleton_distance labels=Presyn_labels min");
	selectWindow("Skeleton_distance-intensity-measurements");
	presyn_neurite = Table.getColumn("Min");
	
	//Table creation pooling the different features necessary for filtering
	Table.create("Results_presynaptic");
	Table.setColumn("Mean_intensity_presynaptic_marker", presyn_intensity);
	Table.setColumn("Min_Neurite_Distance", presyn_neurite);
	Table.rename("Results_presynaptic", "Results");
	
	//Filtering the labels for their intensity in the original channel and their presence within neurites
	syn_Array = newArray;
	j = 0;
	for (i = 0; i < nResults; i++) {
		presyn_cell = getResult("Mean_intensity_presynaptic_marker", i);
		presyn_cell = parseFloat(presyn_cell);
		dist_neurite = getResult("Min_Neurite_Distance", i);
		dist_neurite = parseFloat(dist_neurite);
		if (presyn_cell>=presyn_int && dist_neurite<=maxdist) {
			syn_Array[j] = i+1;
			j = j + 1;
		}
	}
	if (j==0) {
		print("There are no synapses");
	}
	close("Results");
	filtered_string = String.join(syn_Array, ",");
	selectWindow("Presyn_labels");
	run("Select Label(s)", "label(s)=" + filtered_string);
	run("Remap Labels");
	resetMinAndMax();//necessary to update the labels
	//Reassign pixel size
	Stack.setXUnit("micron");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=" + pixelWidth + " pixel_height=" + pixelWidth + " voxel_depth=1.0000000");
	rename("Synapses");
	
	//Create the labelled axons image and fuse it with the synapse labels to analyse the number of synapses per axon
	labelled_skel("Skeleton");
	rename("Neurites_labelled");
	
	//This max is the number of branches
	run("3D Merge Labels", "imagea=Synapses imageb=Neurites_labelled min=" + maxdist + " merge=Intersection");
	//Reassign pixel size
	Stack.setXUnit("micron");
	run("Properties...", "channels=1 slices=1 frames=1 pixel_width=" + pixelWidth + " pixel_height=" + pixelWidth + " voxel_depth=1.0000000");
	run("Set Label Map", "colormap=Spectrum background=Black shuffle");
	saveAs("Tiff", dir + "/Segmented/" + name + "_Axons_and_Synapses");
	rename("Axons_and_Synapses");
	
	//Synapses and neurites need to be relabelled to be like the fused image as the IDs change.
	selectWindow("Synapses");
	run("Analyze Regions", " ");
	syn_id_priorfusion = Table.getColumn("Label");
	syn_id_priorfusion_string = String.join(syn_id_priorfusion);
	
	close("Synapses");//This is to avoid using the wrong image for later calculations
	
	//Create synapses from the fused image to have the proper synapse labels
	selectWindow("Axons_and_Synapses");
	run("Select Label(s)", "label(s)=[" + syn_id_priorfusion_string + "]");
	
	//Save the synapses correctly labeled
	saveAs("Tiff", dir + "/Segmented/" + name + "_Synapses");
	
	//Rename to use later in the script
	rename("Synapses");
	
	//Processing the different arrays to access the axon ids and only have the synapse centroid 
	axonNb = roiManager("count");
	
	selectWindow("Axons_and_Synapses");
	run("Analyze Regions", " ");
	neurite_id_priorfusion = Table.getColumn("Label");
	Array.reverse(neurite_id_priorfusion);
	neurite_id_list = Array.trim(neurite_id_priorfusion, axonNb);
	Array.sort(neurite_id_list);
	neurite_id_list_string = String.join(neurite_id_list);
	
	//Create synapses from the fused image to have the proper synapse labels
	selectWindow("Axons_and_Synapses");
	run("Select Label(s)", "label(s)=[" + neurite_id_list_string + "]");

	saveAs("Tiff", dir + "/Segmented/" + name + "_Neurites_labelled");
	rename("Neurites_labelled_updatedid");
	close("Neurites_labelled");
	
	//Measure neurite length
	getPixelSize(unit, pixelWidth, pixelHeight); //To calibrate the length to µm
	run("Analyze Regions", "pixel_count");
	pixelcount_array = Table.getColumn("PixelCount");
	//Calibrating the pixel count of neurites back to the original unit
	for (i = 0; i < pixelcount_array.length; i++) {
		pixelcount = pixelcount_array[i];
		pixelcount_array[i] = pixelcount * pixelWidth;
	}
	
	//Measure neurite tortuosity
	tortuosity_array = findtortuosity("Neurites_labelled_updatedid");
	
	//Plaque distance
	if (plaque_analysis == "yes") {
		selectWindow("Raw_Image");
		run("Duplicate...", "duplicate channels=" + plaque_channel + "-" + plaque_channel);
		rename("Plaque_raw");
				
		setThreshold(plaque_thresh, 65535, "raw");
		run("Convert to Mask");
		getStatistics(area, mean, min, max, std, histogram);
		if (max != 0) {
			run("Set Measurements...", "area mean standard redirect=None decimal=3");
			run("Analyze Particles...", "size=[plaque_area]-Infinity show=Masks");
			run("Invert LUT");
			rename("Plaque_binary");
			run("Distance Transform 3D");
			rename("Plaque_distance");
			close("Plaque_raw");
			close("Plaque_binary");
			
			run("Intensity Measurements 2D/3D", "input=Plaque_distance labels=Synapses min");
			syn_nnd_plaque = Table.getColumn("Min");
			
			run("Intensity Measurements 2D/3D", "input=Plaque_distance labels=Neurites_labelled_updatedid min");
			neurite_nnd_plaque = Table.getColumn("Min");
			
			close("Plaque_distance");
		}
		else {
			syn_nnd_plaque = newArray(syn_id_priorfusion.length);
			neurite_nnd_plaque = newArray(neurite_id_list.length);
		}
	}
	
	
	//Quantify the number of synapses per axon
	getSynID("Axons_and_Synapses", neurite_id_list, maxdist);
	
	
	//Getting the synapse centroids
	selectWindow("Synapses");
	run("Analyze Regions", "area centroid");
	syn_id_array = Table.getColumn("Label"); //Could not just rename the Label column as the command does not find it...weird bug.
	Table.setColumn("Synapse ID", syn_id_array);
	
	//Adding centroid coordinates and area information to Synapse IDs
	
	syn_centroidX_array = addColumn("Axons_synapses_ID", "Synapses-Morphometry", "Synapse ID", "Centroid.X");
	syn_centroidY_array = addColumn("Axons_synapses_ID", "Synapses-Morphometry", "Synapse ID", "Centroid.Y");
	syn_area_array = addColumn("Axons_synapses_ID", "Synapses-Morphometry", "Synapse ID", "Area");
	
	//Add the new columns to the synapse measurement table
	selectWindow("Axons_synapses_ID");
	Table.setColumn("Centroid.X", syn_centroidX_array);
	Table.setColumn("Centroid.Y", syn_centroidY_array);
	Table.setColumn("Synapse_Area_um2", syn_area_array);
	
	//In case plaque analysis is selected
	if (plaque_analysis == "yes") {
		//Calibrating distance calculations
		for (i = 0; i < syn_nnd_plaque.length; i++) {
			syn_dist_plaque = syn_nnd_plaque[i];
			syn_nnd_plaque[i] = syn_dist_plaque * pixelWidth;
		}
		
		//Adding NND to plaques to Neurite IDs
		selectWindow("Synapses-Morphometry");
		Table.setColumn("Syn_NND_to_plaques", syn_nnd_plaque);
		syn_nnd_plaque_newarray = addColumn("Axons_synapses_ID", "Synapses-Morphometry", "Synapse ID", "Syn_NND_to_plaques");
		
		selectWindow("Axons_synapses_ID");
		Table.setColumn("Syn_NND_to_plaques[um]", syn_nnd_plaque_newarray);
	}

	//Save Synapse measurements
	selectWindow("Axons_synapses_ID");
	saveAs("Results", dir + "/Analysis/Synapses/" + name + "_Synapse_measurements.csv");
	
	//Save Neurites measurements
	selectWindow("Axons_synapse_count");
	Table.setColumn("Neurite_length[um]", pixelcount_array);
	Table.setColumn("Neurite_tortuosity", tortuosity_array);
	
	if (plaque_analysis == "yes") {
		//Calibrating distance calculations
		for (i = 0; i < neurite_nnd_plaque.length; i++) {
			neurite_dist_plaque = neurite_nnd_plaque[i];
			neurite_nnd_plaque[i] = neurite_dist_plaque * pixelWidth;
		}
		
		Table.setColumn("Neurite_NND_to_plaques[um]", neurite_nnd_plaque);
	}
	saveAs("Results", dir + "/Analysis/Neurites/" + name + "_Neurites_measurements.csv");
	
	//Close non important windows
	close("ROI Manager");
	close(name + "_Synapse_measurements.csv");
	close(name + "_Neurites_measurements.csv");
	close("*");
	close("Presyn_raw-intensity-measurements");
	close("Skeleton_distance-intensity-measurements");
	run("Collect Garbage");
	
}

//This function fills information of one table to other table given they share a colum and puts it in a new table
//table1_name = the table that will be used as reference for the expansion
//table2_name = the table that will be used for adding new data to the new table
//column1_name = the column with the shared name between both columns eg Axon ID
//column2_name = then column with the information to add
function addColumn(table1_name, table2_name, column1_name, column2_name) { 
	
	selectWindow(table1_name);
	column1_array = Table.getColumn(column1_name);
	
	selectWindow(table2_name);
	column2_array = Table.getColumn(column1_name);
	
	//loop over column1_array and create the new column with the proper data
	new_array = newArray(column1_array.length);
	for (i = 0; i < column1_array.length; i++) {
		column1_item = column1_array[i];
		for (j = 0; j < column2_array.length; j++) {
			column2_item = column2_array[j];
			if (column1_item == column2_item) {
				new_array[i] = Table.get(column2_name, j);
			}
		}
	}
	return new_array;
}

// This function takes a table with 2 columns with interacting labels and 
// delivers 2 concatenated arrays of column1+column2 and column2+column1
function concatenate_label_table(table, column1, column2) {
	selectWindow(table);
	column1_array = Table.getColumn(column1);
	column2_array = Table.getColumn(column2);
	array1 = Array.concat(column1_array,column2_array);
	array2 = Array.concat(column2_array,column1_array);
	new_table ="Label_relationship";
	Table.create(new_table);
	Table.setColumn(column1, array1);
	Table.setColumn(column2, array2);
	Table.sort(column1);
	return new_table //this is not the table itself but the name of the table
}

//Generates the labelled axon image
//The input should be the skeleton image name or any black image of the same size
//TODO It would be great to find a different way to create this image cause if there are more than 255 Neurites it will give an error
function labelled_skel(image_name) { 
	//Draw the lines on the skeleton image
	selectWindow(image_name);
	run("Duplicate...", "title=Skeleton_labelled");
	run("32-bit");
	roi_count = roiManager("count");
	for (i = 0; i < roi_count; i++) {
		roiManager("Select", i);
		roiManager("Draw");
		run("Replace/Remove Label(s)", "label(s)=255 final=" + i + 1);
	}
	return roi_count;
}

// This function generates a table containing the Axon ID and its interacting Synapses IDs within the max distance allowed by the user
function getSynID(axon_syn_image, axonid_array, maxdist) { 
	//setBatchMode(true);
	//Define the arrays containing the axon ids and syn ids
	setOption("ExpandableArrays", true);
	axonid_array_final = newArray;
	synid_array_final = newArray;
	syncount_array = newArray;
	index = 0;
	
	minaxonid = parseInt(axonid_array[0]);

	selectWindow(axon_syn_image);
	Array.sort(axonid_array);
	for (k = 0; k < axonid_array.length; k++) {
		axonid = parseInt(axonid_array[k]);
		syn_count = 0;
		selectWindow(axon_syn_image);
		run("Select Neighbor Labels", "labels=" + axonid + " radius=" + maxdist);
		rename("temp");
		getStatistics(area, mean, min, max, std, histogram);
		//print(axonid + " - The mean is: " + mean);
		if (mean > 0) {
			run("Analyze Regions", " ");
			synid_array = Table.getColumn("Label");
			
			for (l = 0; l < synid_array.length; l++) {
				synid = parseInt(synid_array[l]);
				//print("My synapse is " + synid + " and my min Axon is " + minaxonid);
				if (minaxonid > synid) {
					//print(synid + " is an axon");
				}
				else {
					//print(synid + " is an not axon");
				}

				if (minaxonid > synid) {
					synid_array_final[index] = synid;
					axonid_array_final[index] = axonid;
					syn_count = syn_count + 1;
					index = index + 1;
				}
				//print(axonid + " - Synapse Nb " + syn_count);
			}
		}
		syncount_array[k] = syn_count;
		close("temp");
	}
	
	
	//setBatchMode(false);
	Table.create("Axons_synapses_ID");
	Table.setColumn("Axon ID", axonid_array_final);
	Table.setColumn("Synapse ID", synid_array_final);
	
	Table.create("Axons_synapse_count");
	Table.setColumn("Axon ID", axonid_array);
	Table.setColumn("Synapse_Nb", syncount_array);
}

// This function accepts a labelled image as input of overlaying neurites and it takes them one by one, applies a closing operation so that
// they are continuous and measures tortuosity. It gives back an array with the tortuosity values per neurite.
function findtortuosity(labelled_neurites_image) { 
	
	//Select the labelled image and measure tortuosity per corrected neurite
	selectWindow(labelled_neurites_image);
	run("Analyze Regions", " ");
	neurite_labels = Table.getColumn("Label");
	
	//Define empty array to fill with tortuosity values
	tortuosity_array = newArray(neurite_labels.length);
	
	//setBatchMode(true);
	for (i = 0; i < neurite_labels.length; i++) {
		label = neurite_labels[i];
		
		//Extract neurite
		run("Crop Label", "label=" + label + " border=10");
		rename("cropped");
		
		//Correct neurite
		disk_radius = 0;
		tortuosity = "Infinity";
		while (tortuosity == "Infinity") {
			run("Morphological Filters", "operation=Dilation element=Disk radius=" + disk_radius);
			run("Skeletonize");
			rename("closed");
			
			//Measure tortuosity and store in empty array
			run("Analyze Regions", "tortuosity");
			selectWindow("closed-Morphometry");
			tortuosity = Table.get("Tortuosity", 0);
			tortuosity_array[i] = tortuosity;
			
			if (tortuosity < 1) {
				tortuosity_array[i] = 1;
			}
			
			disk_radius = disk_radius + 1;
			
			//waitForUser("continue?"); //This line is to test if the while loop works properly
		}

		//Close windows
		close("cropped");
		close("closed");
	}
	//setBatchMode(false);
	
	return tortuosity_array;
}


//Extract a string from another string at the given input smaller string (eg ".")
function getBasename(filename, SubString){
  dotIndex = indexOf(filename, SubString);
  basename = substring(filename, 0, dotIndex);
  return basename;
}

//Return a file list contain in the directory dir filtered by extension.
function getFilesList(dir, fileExtension) {  
  tmplist=getFileList(dir);
  list = newArray(0);
  imageNr=0;
  for (i=0; i<tmplist.length; i++)
  {
    if (endsWith(tmplist[i], fileExtension)==true)
    {
      list[imageNr]=tmplist[i];
      imageNr=imageNr+1;
      //print(tmplist[i]);
    }
  }
  Array.sort(list);
  return list;
}

