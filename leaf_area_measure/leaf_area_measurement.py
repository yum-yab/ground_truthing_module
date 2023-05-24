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

def hsv_filter_fun(hsv, skipcolors, max_distance: float, skipcolor_val = 0.5) -> float:

    hue, saturation, value = hsv
    
    for skipcolor in skipcolors:
        if calculate_color_distance(hsv, skipcolor) < max_distance:
            return skipcolor_val

    if saturation < 0.2:
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

def convert_color(pixelcolor, skipcolors, distance_threshold):

    for i, sc in enumerate(skipcolors):
        if calculate_color_distance(pixelcolor, sc) < distance_threshold:
            return i + 2

    return skimage.color.rgb2gray(pixelcolor)


def convert_hsv_to_greyscale(image: np.ndarray, skipcolors, max_distance) -> np.ndarray:
    """Converts an image to greyscale. Colors in the skipcolor list will be converted to value 2+index"""
    
    result =  np.zeros(image.shape[:2])
        
    for i, row in enumerate(image):
        for j, pixel in enumerate(row):
            result[i, j] = hsv_filter_fun(pixel, skipcolors, max_distance)

    return result



def greyscale_easy_convert(image) -> np.ndarray:

    return skimage.color.rgb2gray(image)

def show_image(image, cmap_val=None):
    fig, ax = plt.subplots()
    if cmap_val:
        plt.imshow(image, cmap="gray")
    else:
        plt.imshow(image)

def build_histogram(image):
    histogram, bin_edges = np.histogram(image, bins=256, range=(0.0, 1.0))
    plt.plot(bin_edges[0:-1], histogram)
    plt.title("Grayscale Histogram")
    plt.xlabel("grayscale value")
    plt.ylabel("pixels")
    plt.xlim(0, 1.0)

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

def calculate_leaf_area_of_path(path: str, leaf_number, a4_multiplier) -> float:

    baseimage = load_image(path)
    hsv_image = skimage.color.rgb2hsv(baseimage)

    greyscale_hsv_filtered = convert_hsv_to_greyscale(hsv_image, [ALPHA_VALUE_HSV], 0.1)
    
    leaf_area_relation = calculate_area_relation_of_mask(greyscale_hsv_filtered)
    print(f"Leaf area relation for {path}: {leaf_area_relation * 100} %")
    return leaf_area_relation * (a4_multiplier * A4_SIZE) 


def compare_image_with_mask(path: str):

    baseimage = load_image(path)
    hsv_image = skimage.color.rgb2hsv(baseimage)

    greyscale_hsv_filtered = convert_hsv_to_greyscale(hsv_image, [ALPHA_VALUE_HSV], 0.1)
    
    show_image(baseimage)
    show_image(hsv_image, cmap_val="hsv")
    show_image(greyscale_hsv_filtered, cmap_val="grey")
    plt.show()


def __main():

    command = sys.argv[1]
    
    directory_path = sys.argv[2]

    if command == "inspect":
       compare_image_with_mask(directory_path) 
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

            results.append(calculate_leaf_area_of_path(fpath, leafnum, factor))
        print(f"Results for {directory_path}: {results}")
        print(f"Number of leafes: {leafnum}")
        print(f"Mean: {sum(results)/leafnum} cm^2")
        print(f"Sum: {sum(results)} cm^2")

if __name__ == "__main__":
    __main()
