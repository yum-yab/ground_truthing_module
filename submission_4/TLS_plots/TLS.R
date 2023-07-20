##Claudia Guimaraes-Steinicke
## Second exercises on Ground truthing
# June 27th 2023

# Packages
install.packages("devtools")
devtools::install_github("akamoske/canopyLazR")
install.packages("lidR")
install.packages("terra")
install.packages("rayshader")

# Load the library
library(devtools)
library(canopyLazR)
library(rLiDAR)
library(forestr)
library(lidR)
library(rayshader)
library(RCSF)
library(rayshader)
library(rgdal)
library(sf)
library(ggplot2)



setwd("/Users/marie-louisekorte/Documents/Uni Leipzig/Semester 2/Ground Truthing/analysis/TLS")


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

nlas <- tls - dtm_tin_tls # normalization (most important part)
plot(nlas, size =4, bg="white")


#############################################################################
# Digital surface model and canopy height model
#############################################################################
# Digital surface models has as input non-normalized point cloud with absolute elevations (uses the sea level as references)
# Canopy height model input is a normalized point cloud which means the derived surface represented by the canopy height (vegetation area)

# Different methods to create DSM and CHM, but basically there are based on grid (raster files) that uses pixel sizes and triangulation of 
#points to assign every grid cell an elevation value.

## fastest way: using point to raster algorithm

# if the cloud is to dense and with finer resolution, this algorithm might loose some grids information
chm <- rasterize_canopy(tls_gc, res =0.05, algorithm =p2r())
plot(chm, col= col)

## CHM with interpolation of empty points
chm_IEP <- rasterize_canopy(tls_gc, res = 0.05, p2r(0.2, na.fill = tin()))  # rasterisation -> fill in gaps of data with interpolated data
plot(chm_IEP, col = col)

chm_IEP <- as(chm_IEP, "Raster")
plot(chm_IEP)


col <- height.colors(25)

### setting an extent to tls raster
aoi <- shapefile("shapefile/polygon.shp")


# check for the extent
crs(chm_IEP) <- "+proj=longlat +datum=WGS84 +no_defs "
aoi                 
chm_IEP 

## setting same extent to chm_IEP

# bb <- extent(12.30909, 12.3099, 51.36535, 51.36598) ## this is the extent of the aoi

chm_IEP <- t(chm_IEP)
bb <- extent( 12.30885, 12.30991, 51.36523, 51.36637) ## corrected aoi
extent(chm_IEP) <- bb
chm_IEP <- setExtent(chm_IEP, bb, keepres = T, snap = T)
crs(chm_IEP) <- ("+proj=utm +zone=33 +datum=WGS84 +units=m +no_defs")


## save 
chm_IEP_aoi <- writeRaster(chm_IEP,'chm_IEP.tif',options=c('TFW=YES'), overwrite=TRUE) #if you want to save
plot(chm_IEP_aoi)

chm_IEP <- crop(chm_IEP, aoi)

plot(chm_IEP)
chm_IEP
hist(chm_IEP)


chm_IEP <- raster('chm_IEP.tif')
## calculate standard deviation of chm_IEP
h_tls_sd = aggregate(chm_IEP, fact = 10, fun = "sd")
plot(h_tls_sd)
hist(h_tls_sd)


##############################################################################
## Download the Sentinel 2 
#############################################################################
h_s2_top <- raster("ETH_GlobalCanopyHeight_DE_CHM_clip.tif")
plot(h_s2_top)
h_s2_top
h_s2_sd <- raster("ETH_GlobalCanopyHeight_DE_STD_clip.tif")
plot(h_s2_sd)

# crs(h_s2_top) <- "+proj=longlat +datum=WGS84 +no_defs "


# Resample chm_IEP to match the resolution and extent of Sentinel-2
h_tls_top <- projectRaster(chm_IEP, h_s2_top, alignOnly = F)
plot(h_tls_top)
h_tls_sd <- projectRaster(h_tls_sd, h_s2_top, alignOnly = F)
plot(h_tls_sd)

##resample?
h_tls_top_res <- resample(h_tls_top, h_s2_top, method = "bilinear")
h_tls_sd_res <- resample(h_tls_sd, h_s2_top, method = "bilinear")

## crop to area of interest
h_s2_top <- crop(h_s2_top, aoi)
h_s2_sd <- crop(h_s2_sd, aoi)

### set the same extent
plot(h_s2_top)
hist(h_s2_top)

plot(h_s2_sd)
hist(h_s2_sd)


################################################################################################
## plot final results

# colors
custom_palette <- c("#ad8f68", "#ffcc00", "#85dd4b", "darkgreen")
col <- c("red", "blue")
# Convert the matrix to a data frame
df_h_s2_top <- as.data.frame(h_s2_top, xy = TRUE)
colnames(df_h_s2_top) <- c("x", "y", "value")

df_h_s2_sd <- as.data.frame(h_s2_top, xy = TRUE)
colnames(df_h_s2_sd) <- c("x", "y", "value")

# Create the ggplot
ggplot(df_h_s2_top, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = custom_palette, limits = c(0, 35)) +
  labs(title = "Sentinel Canopy Height",
       x = "Longitude",
       y = "Latitude",
       fill = "Height")

(ggplot(df_h_s2_sd, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = col, limits = c(0, 10)) +
  labs(title = "Sentinel Canopy Height SD",
       x = "Longitude",
       y = "Latitude",
       fill = "Standard Deviation"))


###############################################################################
# general height-derived metrics
## calculate height from CHM_IEP

ras_final <- aggregate(chm_IEP, fact= 10,fun=max )

res_min<-cellStats(ras_final, 'min')
res_max <-cellStats(ras_final, 'max')
res_mean <-cellStats(ras_final, 'mean')
res_sd <-cellStats(ras_final, 'sd')

plot(ras_final)
res_mean
res_sd
res_max
res_min

ras_final_s <- aggregate(h_s2_top, fact= 10,fun=max )
res_min_s <-cellStats(ras_final_s, 'min')
res_max_s <-cellStats(ras_final_s, 'max')
res_mean_s <-cellStats(ras_final_s, 'mean')
res_sd_s <-cellStats(ras_final_s, 'sd')

res_mean_s
res_min_s
res_max_s
res_sd_s

ras_final_sd <- aggregate(h_s2_sd, fact= 10,fun=max )
res_min_sd <-cellStats(ras_final_sd, 'min')
res_max_sd <-cellStats(ras_final_sd, 'max')
res_mean_sd <-cellStats(ras_final_sd, 'mean')
res_sd_sd <-cellStats(ras_final_sd, 'sd')

res_mean_sd
res_min_sd
res_max_sd
res_sd_sd

#end
###############################################################################