# Leaf area measure script

## 1. Preparing the images

First task is to reduce images to the essence, I used gimp for this with the following workflow:

1. Load the image in gimp
2. Use the `lasso-select tool` for selecting the corners of the A4 paper
3. Press `CTRL + i` for inverting the selection
4. Press `CTRL + x` for cutting out everything thats not on the paper
5. Use `Image > Crop to content` to reduce the image size
    - this step is optional since alpha channel (= transparency) is ignored in the script, but this reduces file size and therefor makes it a bit faster
6. Save images in proper format for script:
    - Name of the file `{leaf-number}_someuniquename_{double}.jpg` (only use `double` if two A4 papers were used)
    - save all files of one species in one directory


## 2. Setting up env

```bash
git clone https://github.com/yum-yab/ground_truthing_module
cd leaf_area_measure
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
```

## 3. Actually calculating the sizes

For calculating the sizes of one species run 

```bash
python leaf_area_measurement.py calculate {path_to_dir}
```

So for example the following command will calculate all the maple leaf sizes:

```bash
python leaf_area_measurement.py calculate leaf_images/cropped/ahorn
```

## 4. Debugging weird measures

For debugging specific images run

```bash
python leaf_area_measurement.py inspect leaf_images/cropped/ahorn/1_ahorn01.jpg
```

This will open three images: The original, one in HSV color space and the final binary mask (grey areas here are the transparent parts of the image)
