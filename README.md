# Neurite and Synapse Analysis Script

## Description

This ImageJ macro script processes 2D multi-channel microscopy images to detect and analyze neurites and synapses. It uses specified channels to identify neurites and presynaptic markers (synapses), segments these structures, and performs quantitative analyses such as counting synapses per neurite, measuring neurite length, and calculating neurite tortuosity. Optionally, the script can also segment plaques and measure the distances of neurites and synapses to these plaques.

## Features

- **Synapse Segmentation**: Detects and labels presynaptic vesicles from multi-channel images.
- **Manual or Automatic ROI Selection**: Allows users to draw regions of interest (ROIs) manually or use pre-defined ROI files.
- **Quantitative Analysis**: Measures synapse counts per neurite, neurite length, and neurite tortuosity.
- **Plaque Segmentation (Optional)**: Segments plaques and calculates distances from neurites and synapses to plaques.
- **Batch Processing**: Processes multiple images in a specified directory.
- **Result Outputs**: Saves segmented images and quantitative results in organized directories.

## Requirements

- **Fiji (ImageJ)**: [Download Fiji](https://fiji.sc/)
- **Plugins**:
  - **StarDist**: For segmentation of presynaptic vesicles.
    - Installation instructions: [StarDist on ImageJ Wiki](https://imagej.net/plugins/stardist)
  - **MorphoLibJ**: For mathematical morphology operations.
    - Installation instructions: [MorphoLibJ on ImageJ Wiki](https://imagej.net/plugins/morpholibj)
- **Java**: Ensure that Java is installed and properly configured for Fiji.

## Installation

1. **Install Fiji**:
   - Download and install Fiji from the [official website](https://fiji.sc/).

2. **Install Required Plugins**:
   - **StarDist**:
     - In Fiji, go to `Help` > `Update...`.
     - Click on `Manage update sites`.
     - Scroll down and check the box next to `StarDist`.
     - Click `Close`, then `Apply changes`, and restart Fiji if prompted.
   - **MorphoLibJ**:
     - In the same `Manage update sites` window, check the box next to `IBMP-CNRS`.
     - Click `Close`, then `Apply changes`, and restart Fiji if prompted.

3. **Download the Scripts**:
   - Save the script file (e.g., `Neurite_Synapse_Analysis.ijm`) to your local machine.

4. **Add the Script to Fiji**:
   - Drag and drop the script Neurite_Synapse_Analysis.ijm.

## Usage

1. **Prepare Your Data**:
   - Organize your 2D multi-channel images (`.nd2` or `.tif` files) in a single directory.
   - If using pre-defined ROIs, ensure that ROI `.zip` files are in a separate directory and correspond to the image files.

2. **Launch the Script**:
   - Open Fiji.
   - Navigate to `Plugins` > `Macros` > `Run...`.
   - Select the `Neurite_Synapse_Analysis.ijm` script file.

3. **Configure Script Parameters**:

   - **File Input**:
     - **File directory**: Browse to select the directory containing your image files.
     - **ROI directory**: Browse to select the directory containing your ROI `.zip` files.

   - **Parameters for Synapse Segmentation**:
     - **Channel containing the neurite marker**: Enter the channel number for neurites (default: **4**).
     - **Channel containing the presynaptic marker**: Enter the channel number for synapses (default: **3**).
     - **Maximum size filter for segmented presynaptic vesicles [px²]**: Set the maximum vesicle size (default: **80**).
     - **Minimum size filter for segmented presynaptic vesicles [px²]**: Set the minimum vesicle size (default: **10**).
     - **Intensity filter for Presynaptic marker**: Set the intensity threshold for vesicle segmentation (default: **80**).
     - **Maximum distance from presynaptic vesicle surface to neurite [µm]**: Define the maximum distance to consider a vesicle as a synapse (default: **0**).

   - **ROI Selection**:
     - **Draw ROIs manually**: Choose `yes` to manually draw neurite ROIs, or `no` to use pre-drawn ROI files.

   - **Parameters for Plaque Segmentation (Optional)**:
     - **Plaque distance analysis**: Choose `yes` to enable plaque segmentation and distance analysis.
     - **Channel containing the plaques marker**: Enter the channel number for plaques (default: **1**).
     - **Minimum size filter for plaques [µm²]**: Set the minimum plaque size (default: **1**).
     - **Intensity filter for plaque segmentation**: Set the intensity threshold for plaque segmentation (default: **1000**).

   - **File Suffix**:
     - **File suffix**: Select the file extension of your images (`.nd2` or `.tif`).

4. **Run the Script**:
   - Click `OK` to start the processing.
   - If manual ROI drawing is enabled, you will be prompted to draw neurite skeletons using the freehand line tool:
     - Use the freehand line tool to trace neurites.
     - After drawing each neurite, add it to the ROI Manager (`Ctrl + T` or `Command + T`).
     - Once all neurites are traced and added, proceed to the next step.

5. **Processing**:
   - The script will process each image file in the directory.
   - It performs the following steps:
     - Opens the image and corresponding ROI (if not drawing manually).
     - Enhances contrast for visualization.
     - Segments synaptic channel using StarDist.
     - Filters vesicles based on size and intensity thresholds.
     - Generates a skeletonized image of neurites.
     - Labels neurites and synapses.
     - Measures synapse counts per neurite, neurite length, and tortuosity.
     - Optionally segments plaques and measures distances to neurites and synapses.
     - Saves results and segmented images.

6. **Results**:
   - **Segmented Images**: Saved in the `Segmented` folder inside your image directory.
     - `*_Axons_and_Synapses.tif`: Image showing labeled neurites and synapses.
     - `*_Synapses.tif`: Labeled synapses image.
     - `*_Neurites_labelled.tif`: Labeled neurites image.
   - **Quantitative Data**: Saved in the `Analysis` folder inside your image directory.
     - **Synapses** (`Analysis/Synapses`):
       - `*_Synapse_measurements.csv`: Contains synapse IDs, corresponding neurite IDs, centroids, areas, and optionally distances to plaques.
     - **Neurites** (`Analysis/Neurites`):
       - `*_Neurites_measurements.csv`: Contains neurite IDs, synapse counts, lengths, tortuosities, and optionally distances to plaques.

## Output Files

- **Segmented Images**:
  - **`[ImageName]_Axons_and_Synapses.tif`**: Composite image with labeled neurites and synapses.
  - **`[ImageName]_Synapses.tif`**: Image with labeled synapses.
  - **`[ImageName]_Neurites_labelled.tif`**: Image with labeled neurites.

- **Quantitative Data**:
  - **Synapse Measurements (`*_Synapse_measurements.csv`)**:
    - **Synapse ID**: Identifier for each synapse.
    - **Axon ID**: Corresponding neurite identifier.
    - **Centroid.X, Centroid.Y**: Coordinates of synapse centroids.
    - **Synapse_Area_um2**: Area of each synapse in square micrometers.
    - **Syn_NND_to_plaques[um]** (if plaque analysis is enabled): Nearest neighbor distance to plaques.

  - **Neurite Measurements (`*_Neurites_measurements.csv`)**:
    - **Axon ID**: Identifier for each neurite.
    - **Synapse_Nb**: Number of synapses per neurite.
    - **Neurite_length[um]**: Length of each neurite in micrometers.
    - **Neurite_tortuosity**: Tortuosity value of each neurite.
    - **Neurite_NND_to_plaques[um]** (if plaque analysis is enabled): Nearest neighbor distance to plaques.

## License

This script is released under the [MIT License](https://opensource.org/licenses/MIT).

## Author

**Nicolas Peredo, PhD**  
Image Analysis Expert
VIB BioImaging Core Leuven - Center for Brain and Disease Research  
Nikon Center of Excellence  

## References

When publishing data analyzed with this script, please cite the following plugins:

- **MorphoLibJ**:
  - Legland, D., Arganda-Carreras, I., & Andrey, P. (2016). MorphoLibJ: Integrated library and plugins for mathematical morphology with ImageJ. *Bioinformatics*, 32(22), 3532–3534. doi:[10.1093/bioinformatics/btw413](https://doi.org/10.1093/bioinformatics/btw413)

- **StarDist**:
  - Schmidt, U., Weigert, M., Broaddus, C., & Myers, G. (2018). Cell Detection with Star-Convex Polygons. In *Medical Image Computing and Computer-Assisted Intervention – MICCAI 2018* (pp. 265–273). Springer International Publishing. doi:[10.1007/978-3-030-00934-2_30](https://doi.org/10.1007/978-3-030-00934-2_30)

## Contact

For questions or issues regarding this script, please contact Nicolas Peredo (nicolas.peredo@vib.be) at the VIB BioImaging Core Leuven.
