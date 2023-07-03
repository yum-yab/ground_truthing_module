##Claudia Guimaraes-Steinicke
## Second exercises on Ground truthing
# June 27th 2023

# Packages
install.packages("devtools")
# you need devtools to run install_github
library(devtools)
install_github("akamoske/canopyLazR")
install.packages("lidR")
install.packages("rLiDAR")
install.packages("terra", repos='https://rspatial.r-universe.dev')
install.packages("rayshader")

# Load the library
library(canopyLazR)
library(rLiDAR)
library(forestr)
library(lidR)
library(rayshader)
library(RCSF)

setwd("/home/denis/workspace/data/canopy_lidar_data")


## Question:

## How estimates of height based on canopy height model obtained by the TLS is comparable with Sentinel-2?

## Data

## 1) Sentinel - 2 height data
## You already downloaded from the moddle 
# (link:https://drive.google.com/drive/folders/1Jn1_xpkWe2nE3kYgdDhV0wgtwlFw-R6D?usp=sharing)

## 2) TLS data
# Please download from here:
#(link: https://drive.google.com/drive/folders/1vVAw7OVJiZhjjRYNFP3MsOBjyNRjXTOY?usp=sharing)

### Read TLS data 

tls <- readLAS("Merge_Crane.las") 
summary(tls)
las_check(tls)

### Ground classification
# algorithm pmf means Ground segmentation algorithm described by Zhang et al. 2003 who implemented ground classification
# based on 3D point cloud and not on raster-based. See help function with pmf (adapted to airborne data). 
# the computation occurs on a sequence of windows sizes and thresholds.
# There are other ground segmentation algorithms as gnd_csf and gnd_mcc

tls_gc <- classify_ground(tls, algorithm = csf()) ## cloth filter

plot(tls_gc, color = "Classification", size = 3, bg = "white")

###############################################################################
# Digital terrain model

# After processing the classification of what are the ground points and above ground points,
# one can describe an "image" of the ground points as mesh. 
# There many different algorithms to calculate DTM, such as triangular irregular network, Invert distance weighting,
# Kriging, etc. It is basically a interpolation of points to describe the ground surface.

###############################################################################
# Triangular irregular network (TIN)
# It uses the nearest neighbour to complete the missing pixel out of the convex hull of the ground points

dtm_tin_tls <- rasterize_terrain(tls_gc, res= 0.05, algorithm= tin())

plot_dtm3d(dtm_tin_tls, bg= "white")

###############################################################################

library(rayshader)
dtm_tls <- raster::raster(dtm_tin_tls)
dtm_tls <- as(dtm_tls, "Raster")
plot(dtm_tls)


###############################################################################
################################################################################
## Height normalization
# Remove the influence of the terrain on above ground measurements. This allows
# a directly comparison of vegetation heights and different analysis across area,
# plots, etc.
# We use the terrain surface to normalize with 

nlas <- tls - dtm_tin_tls # normalization
png(filename="/home/denis/workspace/uni/ground_truthing/submission_4/images/normalized_tls.png")
plot(nlas, size =4, bg="white")
dev.off()

#############################################################################
# Digital surface model and canopy height model
#############################################################################
# Digital surface models has as input non-normalized point cloud with absolute elevations (uses the sea level as references)
# Canopy height model input is a normalized point cloud which means the derived surface represented by the canopy height (vegetation area)

# Different methods to create DSM and CHM, but basically there are based on grid (raster files) that uses pixel sizes and triangulation of 
#points to assign every grid cell an elevation value.

col <- height.colors(25)

## fastest way: using point to raster algorithm


# if the cloud is to dense and with finer resolution, this algorithm might loose some grids information

chm <- rasterize_canopy(tls_gc, res =0.05, algorithm =p2r())

plot(chm, col= col)

# ## CHM with interpolation of empty points
chm_IEP <- rasterize_canopy(tls_gc, res = 0.05, p2r(0.2, na.fill = tin()))
plot(chm_IEP, col = col)

chm_IEP <- as(chm_IEP, "Raster")
crs(chm_IEP) <- ("+proj=utm +zone=33 +datum=WGS84 +units=m +no_defs")
plot(chm_IEP)


### setting an extent to tls raster
aoi <- shapefile("TLS_area.shp")

# check for the extent
aoi
chm_IEP

## setting same extent to chm_IEP

bb <- extent(12.30909, 12.3099, 51.36535, 51.36598) ## this is the extent of the aoi
extent(chm_IEP) <- bb
chm_IEP <- setExtent(chm_IEP, bb, keepres = T, snap = T)
plot(chm_IEP)
chm_IEP
hist(chm_IEP)

#chm_IEP_aoi <- writeRaster(chm_IEP,'chm_IEP.tif',options=c('TFW=YES'), overwrite=TRUE) #if you want to save

## calculate standard deviation of chm_IEP
h_tls_sd = aggregate(chm_IEP, fact = 10, fun = "sd")
plot(h_tls_sd)
hist(h_tls_sd)
##############################################################################
## Download the Sentinel 2 
#############################################################################
h_s2_top <- raster("sentinel_2/ETH_GlobalCanopyHeight_DE_CHM_clip.tif")
plot(h_s2_top)
h_s2_top
h_s2_sd <- raster("sentinel_2/ETH_GlobalCanopyHeight_DE_STD_clip.tif")
plot(h_s2_sd)



# Resample chm_IEP to match the resolution and extent of Sentinel-2

h_tls_top <- projectRaster(chm_IEP, h_s2_top, alignOnly = F)
h_tls_top
h_tls_sd <- projectRaster(h_tls_sd, h_s2_top, alignOnly = F)
h_tls_sd

##
resample?
  h_tls_top_res <- resample(h_tls_top, h_s2_top, method = "bilinear")
h_tls_sd_res <- resample(h_tls_sd, h_s2_top, method = "bilinear")

# crop to area of interest
library(rgdal)


h_s2_top <- mask(h_s2_top, aoi)
h_s2_sd <- mask(h_s2_sd, aoi)

### set the same extent


h_s2_top <- crop(h_s2_top, aoi)
plot(h_s2_top)
hist(h_s2_top)
h_s2_sd <- crop(h_s2_sd, aoi)
plot(h_s2_sd)
hist(h_s2_sd)
###############################################################################
# general height-derived metrics

## calculate height from CHM_IEP

ras_final <- aggregate(chm_IEP, fact= 10,fun=max )

res_min<-cellStats(ras_final, 'min')
res_max <-cellStats(ras_final, 'max')
res_mean <-cellStats(ras_final, 'mean')
res_sd <-cellStats(ras_final, 'sd')

#end
###############################################################################