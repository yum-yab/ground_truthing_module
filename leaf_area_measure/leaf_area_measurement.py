from os import listdir
from os.path import isfile
import sys
from typing import List
import skimage.color
import skimage.filters
import imageio.v3 as iio

import matplotlib.pyplot as plt
import numpy as np

# Tutorial found here: https://datacarpentry.org/image-processing/07-thresholding

# in cm^2
A4_SIZE = 21.0 * 29.7 


ALPHA_VALUE_HSV = [0.687, 0.983, 0.455]

def calculate_color_distance(sourcecolor, targetcolor):
    distance = 0.0

    for i in range(3):
        distance += abs(sourcecolor[i] - targetcolor[i])

    return distance



def load_image(path: str) -> np.ndarray:
    return iio.imread(uri=path)

def calculate_area_relation_of_mask(mask: np.ndarray) -> float:
    

    leaf_pixel_count = 0
    
    paper_pixel_count = 0

    for row in mask:
        for pixelval in row:

            if pixelval == 0.0:
                # pixel is black => its the leaf
                leaf_pixel_count += 1
            elif pixelval == 1.0:
                paper_pixel_count += 1
            else:
                # the alpha channel
                continue

    total_paper_area = leaf_pixel_count + paper_pixel_count

    return (leaf_pixel_count / total_paper_area) 


class LeafAreaMeasurer:

    def __init__(self, saturation_threshold: float = 0.2, skipcolors: List = [ALPHA_VALUE_HSV], max_skipping_distance: float = 0.1) -> None:
        """Class for calculating the Area of images. 
        saturation_threshold: Is the threshold at which something is not considered a 'leaf' anymore
        skipcolors: List of hsv colors (as triple) which are not part of the area (e.g. the alpha channel)
        max_skipping_distance: Is the distance a pixel can be away from the skipping color to be considered skipping"""
        
        self.saturation_threshold = saturation_threshold
        self.skipcolors = skipcolors
        self.max_skipping_distance = max_skipping_distance


    def hsv_filter_fun(self, hsv_color_pixel, skipcolor_val = 0.5) -> float:
    
        hue, saturation, value = hsv_color_pixel
        
        for skipcolor in self.skipcolors:
            if calculate_color_distance(hsv_color_pixel, skipcolor) < self.max_skipping_distance:
                return skipcolor_val
    
        if saturation < self.saturation_threshold:
            # this filters out grey
            if value < 0.6:
                # it is grey
                return 1.0
            else:
                # it is white
                return 1.0
        else:
            # it is the leaf
            return 0.0



    def convert_hsv_to_greyscale(self, image: np.ndarray) -> np.ndarray:
        """Converts an image to mask of three values: White for paper, black for leafs, grey for not considered area."""
        
        result =  np.zeros(image.shape[:2])
            
        for i, row in enumerate(image):
            for j, pixel in enumerate(row):
                result[i, j] = self.hsv_filter_fun(pixel)
    
        return result

    def calculate_leaf_area_of_path(self, path: str, a4_multiplier) -> float:
    
        baseimage = load_image(path)
        hsv_image = skimage.color.rgb2hsv(baseimage)
    
        greyscale_hsv_filtered = self.convert_hsv_to_greyscale(hsv_image)
        
        leaf_area_relation = calculate_area_relation_of_mask(greyscale_hsv_filtered)
        print(f"Leaf area relation for {path}: {leaf_area_relation * 100} %")
        return leaf_area_relation * (a4_multiplier * A4_SIZE) 

    def compare_image_with_mask(self, path: str):
    
        baseimage = load_image(path)
        hsv_image = skimage.color.rgb2hsv(baseimage)
    
        greyscale_hsv_filtered = self.convert_hsv_to_greyscale(hsv_image)
        
        show_image(baseimage)
        show_image(hsv_image)
        show_image(greyscale_hsv_filtered, cmap_val="gray")
        plt.show()


def show_image(image, cmap_val=None):
    fig, ax = plt.subplots()
    if cmap_val:
        plt.imshow(image, cmap=cmap_val)
    else:
        plt.imshow(image)


def __main():

    command = sys.argv[1]
    
    directory_path = sys.argv[2]
    
    leaf_area_measurer = LeafAreaMeasurer()

    if command == "inspect":
       leaf_area_measurer.compare_image_with_mask(directory_path) 
    elif command == "calculate":
        all_file_paths = [f"{directory_path}/{fname}" for fname in listdir(directory_path) if isfile(f"{directory_path}/{fname}")]
        
        results = []
        leafnum = 0
        for fpath in all_file_paths:
            fname = fpath.split("/")[-1]
            if "double" in fname:
                factor = 2
            else:
                factor = 1

            leafnum += int(fname.split("_")[0])

            results.append(leaf_area_measurer.calculate_leaf_area_of_path(fpath, factor))
        print(f"Results for {directory_path}: {results}")
        print(f"Number of leafes: {leafnum}")
        print(f"Mean: {sum(results)/leafnum} cm^2")
        print(f"Sum: {sum(results)} cm^2")

if __name__ == "__main__":
    __main()
