library(raster)

# set your wd to where you have the downloaded data
setwd()



# Load the two raster files

h_uav_dsm <- raster("uav/cloudcompare_dsm_v2.tif")

crs(h_uav_dsm) <- ("+proj=utm +zone=33 +datum=WGS84 +units=m +no_defs")


h_uav_dsm <- raster("uav/DJI_202305311408_001_crane-2022-05_dem.tif")

# set 0 to NA

h_uav_dsm <- reclassify(h_uav_dsm, cbind(0, NA))


h_s2_top <- raster("sentinel_2_height/ETH_GlobalCanopyHeight_DE_CHM_clip.tif")

h_s2_sd <- raster("sentinel_2_height/ETH_GlobalCanopyHeight_DE_STD_clip.tif")


plot(h_uav_dsm-147)

h_uav_top = h_uav_dsm - 147

# calculate standard deviation per ~25m² pixels

h_uav_sd = aggregate(h_uav_top, fact = 10, fun = "sd")


# Resample raster1 to match the resolution and extent of raster2

# projectRaster() - projects values of 1 raster object to a new object raster with another projection projectRaster(from, to, alignOnly)
h_uav_top <- projectRaster(h_uav_top, h_s2_top, alignOnly = F)

h_uav_sd <- projectRaster(h_uav_sd, h_s2_top, alignOnly = F)


h_uav_top_res <- resample(h_uav_top, h_s2_top, method = "bilinear")

h_uav_sd_res <- resample(h_uav_sd, h_s2_top, method = "bilinear")



# crop to area of interest

aoi <- shapefile("aoi.shp")

h_uav_top_res <- mask(h_uav_top_res, aoi)

h_uav_sd_res <- mask(h_uav_sd_res, aoi)

h_s2_top <- mask(h_s2_top, aoi)

h_s2_sd <- mask(h_s2_sd, aoi)


h_uav_top_res <- crop(h_uav_top_res, aoi)

h_uav_sd_res <- crop(h_uav_sd_res, aoi)

h_s2_top <- crop(h_s2_top, aoi)

h_s2_sd <- crop(h_s2_sd, aoi)

# create plotting space
par(mfrow = c(2, 2))

# Plot 1
plot(h_uav_top_res, main = "h_uav_top_res")

# Plot 2
plot(h_uav_sd_res, main = "h_uav_sd_res")

# Plot 3
plot(h_s2_top, main = "h_s2_top")

# Plot 4
plot(h_s2_sd, main = "h_s2_sd")

pdf("combined_plot.pdf", width = 80, height = 12)

# Plot the combined figure
par(mfrow = c(2, 2))
plot(h_uav_top_res, main = "h_uav_top_res")
plot(h_uav_sd_res, main = "h_uav_sd_res")
plot(h_s2_top, main = "h_s2_top")
plot(h_s2_sd, main = "h_s2_sd")

# Add a title for the combined plot
title("Height Plots, UAV and S2")

# Close the PDF device
dev.off()


