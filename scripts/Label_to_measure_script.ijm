// @String (visibility=MESSAGE, value="Script for assigning measure to a labelled image", required=false) msg1
// @ File(label="File directory", style="directory") dir
// @ File (label="Select a pooled analysis file") csv_file_path
// @ String (label="Plaque distance analysis", choices={"Axon ID", "Synapse ID"}, style="listBox") label_columnName
// @ String (label="Metric to assign to the labelled image", choices={"Synapse_Nb", "Neurite_length[um]", "Synapse Nb/um", "Neurite_tortuosity", "Neurite_NND_to_plaques", "Mean NND to closest synapse [um]", "Syn_NND_to_plaques", "NND to closest synapse [um]", "NND to closest 2 synapse [um]", "NND to closest 3 synapse [um]", "NND to closest 4 synapse [um]"}, style="listBox") feature_byuser
// @ String (label="LUT for metric", choices={"Fire", "Ice", "Spectrum", "Red-Green"}, style="listBox") lut

 
if (label_columnName == "Axon ID") {
	csv_file = "Pooled_results_neurites.csv";
	type = "_Neurites_labelled.tif";	
}
else {
	csv_file = "Pooled_results_synapses.csv";
	type = "_Synapses.tif";
}

//Open the pooled results table
open(csv_file_path);

//Create directory to stored metric labelled images
File.makeDirectory(dir + File.separator + "Metric_images");

//Get image filelist
file_list = getFilesList(dir, type);

//for (files = 0; files < file_list.length; files++) {
for (files = 0; files < 1; files++) {
	file = file_list[files];
	open(dir + File.separator + file);
	
	//File selection and extraction of the different columns of interest
	selectWindow(csv_file);
	
	label_column = Table.getColumn(label_columnName);
	filename_column = Table.getColumn("Filename");
	feature_column = Table.getColumn(feature_byuser);
	
	file_basename = getBasename(file, type);
	
	setOption("ExpandableArrays", true);
	label_column_filtered = newArray();
	feature_column_filtered = newArray();
	
	filtered_columns_count = 0;
	for (i = 0; i < label_column.length; i++) {
		filename = filename_column[i];
		if (filename == file_basename) {
			label_column_filtered[filtered_columns_count] = label_column[i];
			feature_column_filtered[filtered_columns_count] = feature_column[i];
			filtered_columns_count = filtered_columns_count + 1;
		}
	}
	
	selectWindow(file);
	run("Duplicate...", "title=Labels_tomeasure");
	for (i = 0; i < label_column_filtered.length; i++) {
		label = label_column_filtered[i];
		feature = feature_column_filtered[i];
		run("Replace/Remove Label(s)", "label(s)=" + label + " final=" + feature);
	}
	
	//Change LUT and restart axes
	run("Set Label Map", "colormap=" + lut + " background=Black");
	resetMinAndMax();
	
	//Save images
	saveAs("Tiff", dir + File.separator + "Metric_images/" + file_basename + "_" + feature_byuser);
	
	//Close open images
	close("*");
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
