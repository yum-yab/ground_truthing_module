library(raster)

# set your wd to where you have the downloaded data
setwd()

userpath <- "C:/Users/fabrikat/Documents/submission3/"

# Load the two raster files

h_uav_dsm <- raster(paste(userpath, "uav/cloudcompare_dsm_v2.tif", sep=""))

crs(h_uav_dsm) <- ("+proj=utm +zone=33 +datum=WGS84 +units=m +no_defs")


h_uav_dsm <- raster(paste(userpath, "/uav/DJI_202305311408_001_crane-2022-05_dem.tif", sep=""))

# set 0 to NA

h_uav_dsm <- reclassify(h_uav_dsm, cbind(0, NA))


h_s2_top <- raster(paste(userpath, "sentinel_2_height/ETH_GlobalCanopyHeight_DE_CHM_clip.tif", sep=""))

h_s2_sd <- raster(paste(userpath, "sentinel_2_height/ETH_GlobalCanopyHeight_DE_STD_clip.tif", sep=""))


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

aoi <- shapefile(paste(userpath, "shapefile/polygon.shp"))

h_uav_top_res <- mask(h_uav_top_res, aoi)

h_uav_sd_res <- mask(h_uav_sd_res, aoi)

h_s2_top <- mask(h_s2_top, aoi)

h_s2_sd <- mask(h_s2_sd, aoi)


h_uav_top_res <- crop(h_uav_top_res, aoi)

h_uav_sd_res <- crop(h_uav_sd_res, aoi)

h_s2_top <- crop(h_s2_top, aoi)

h_s2_sd <- crop(h_s2_sd, aoi)

h_res <- h_uav_top_res - h_s2_top

# create plotting space
par(mfrow = c(2, 2))

# Plot 1
plot(h_uav_top_res, main = "UAV height estimation")

# Plot 2
plot(h_uav_sd_res, main = "UAV standard deviation")

# Plot 3
plot(h_s2_top, main = "Sentinel-2 height estimation")

# Plot 4
plot(h_s2_sd, main = "Sentinel-2 standard deviation")

# Plot 5
plot(h_res, main = "Height Residuals", xlab = "hallo")


png(paste(userpath, "uav_height.png",sep=""), width = 400, height = 500)
plot(h_uav_top_res, main = "UAV canopy height", ylab= "Latitude", xlab="Longitude")
dev.off()

png(paste(userpath, "uav_height_hist.png",sep=""), width = 400, height = 500)
hist(h_uav_top_res, main = "UAV canopy height", col = '#568fda', ylim = c(0,20), ylab="Frequency", xlab="Height in m", xlim = c(0,40), breaks = 20)
dev.off()

png(paste(userpath, "uav_sd_hist.png",sep=""), width = 400, height = 500)
hist(h_uav_sd_res, main = "UAV standard deviation", col = '#568fda', ylim = c(0,60), ylab="Frequency", xlab="Deviation in m", xlim = c(0,10), breaks = 20)
dev.off()

png(paste(userpath, "uav_sd.png",sep=""), width = 400, height = 500)
plot(h_uav_sd_res, main = "UAV standard deviation", ylab= "Latitude", xlab="Longitude")
dev.off()

png(paste(userpath, "s2_height_hist.png",sep=""), width = 400, height = 500)
hist(h_s2_top, main = "Sentinel-2 canopy height", col = '#568fda', ylim = c(0,40), ylab="Frequency", xlab="Height in m", xlim = c(29,32), breaks = 20)
dev.off()

png(paste(userpath, "s2_height.png",sep=""), width = 400, height = 500)
plot(h_s2_top, main = "Sentinel-2 canopy height", ylab= "Latitude", xlab="Longitude")
dev.off()

png(paste(userpath, "s2_sd_hist.png",sep=""), width = 400, height = 500)
hist(h_s2_sd, main = "Sentinel-2 standard deviation", col = '#568fda', ylim = c(0,100), ylab="Frequency", xlab="Deviation in m", xlim = c(5,8), breaks = 20)
dev.off()

png(paste(userpath, "s2_sd.png",sep=""), width = 400, height = 500)
plot(h_s2_sd, main = "Sentinel-2 standard deviation", ylab= "Latitude", xlab="Longitude")
dev.off()

png(paste(userpath, "residuals.png",sep=""), width = 400, height = 500)
plot(h_res, main = "Residuals of CHM", ylab= "Latitude", xlab="Longitude")
dev.off()


pdf(paste(userpath, "combined_plot.pdf", sep=""), width = 10, height = 14)

# Plot the combined figure
par(mfrow = c(2, 2))
#par(mar = c(10, 10, 10, 10)) 

hist(h_uav_top_res, main = "UAV canopy height", col = '#568fda', ylim = c(0,20), ylab="Frequency", xlab="Height in m", xlim = c(0,40), breaks = 20)
plot(h_uav_top_res, main = "UAV canopy height", ylab= "Latitude", xlab="Longitude")

hist(h_uav_sd_res, main = "UAV standard deviation", col = '#568fda', ylim = c(0,60), ylab="Frequency", xlab="Deviation in m", xlim = c(0,10), breaks = 20)
plot(h_uav_sd_res, main = "UAV standard deviation", ylab= "Latitude", xlab="Longitude")

hist(h_s2_top, main = "Sentinel-2 canopy height", col = '#568fda', ylim = c(0,40), ylab="Frequency", xlab="Height in m", xlim = c(29,32), breaks = 20)
plot(h_s2_top, main = "Sentinel-2 canopy height", ylab= "Latitude", xlab="Longitude")

hist(h_s2_sd, main = "Sentinel-2 standard deviation", col = '#568fda', ylim = c(0,100), ylab="Frequency", xlab="Deviation in m", xlim = c(5,8), breaks = 20)
plot(h_s2_sd, main = "Sentinel-2 standard deviation", ylab= "Latitude", xlab="Longitude")

plot(h_res, main = "Residuals of CHM", ylab= "Latitude", xlab="Longitude")

# Close the PDF device
dev.off()


