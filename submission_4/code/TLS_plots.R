##Claudia Guimaraes-Steinicke
## Second exercises on Ground truthing
# June 27th 2023

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


setwd("/home/denis/workspace/uni/ground_truthing/submission_4/code")


### colorbar 
col <- height.colors(25)

### setting an extent to tls raster
aoi <- shapefile("shapefile/polygon.shp")
aoi


### TLS canopy height model
chm_IEP_new <- raster('chm_IEP.tif')
chm_IEP <- crop(chm_IEP_new, aoi)
plot(chm_IEP_new)


## calculate standard deviation of chm_IEP
h_tls_sd_new = aggregate(chm_IEP, fact = 10, fun = "sd")
plot(h_tls_sd_new)
hist(h_tls_sd_new)


##############################################################################
## Download the Sentinel 2 
#############################################################################
h_s2_top <- raster("ETH_GlobalCanopyHeight_DE_CHM_clip.tif")
plot(h_s2_top)
h_s2_top
h_s2_sd <- raster("ETH_GlobalCanopyHeight_DE_STD_clip.tif")
plot(h_s2_sd)


# Resample chm_IEP to match the resolution and extent of Sentinel-2
h_tls_top <- projectRaster(chm_IEP, h_s2_top, alignOnly = F)
plot(h_tls_top)
h_tls_sd <- projectRaster(h_tls_sd_new, h_s2_top, alignOnly = F)
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
col <- c("blue", "#3bbce7", "#a931f3", "red")

# Convert the matrix to a data frame
## full res chm
df_h_tls_top <- as.data.frame(chm_IEP, xy = TRUE)
colnames(df_h_tls_top) <- c("x", "y", "value")

df_h_tls_sd <- as.data.frame(h_tls_sd_new, xy = TRUE)
colnames(df_h_tls_sd) <- c("x", "y", "value")

ggplot(df_h_tls_top, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = custom_palette, limits = c(0, 35)) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 20)) +
  scale_x_continuous(limits = c(12.30897, 12.30973), expand = c(0, 0)) +
  scale_y_continuous(limits = c(51.36527, 51.36638), expand = c(0, 0)) +
  coord_equal() + 
  labs(title = "TLS Canopy Height",
       x = "Longitude",
       y = "Latitude",
       fill = "Height")
ggsave("../TLS_figures/chm_height_full_res.png", dpi = 300)

ggplot(df_h_tls_sd, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = col, limits = c(0, 15)) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 20)) +
  scale_x_continuous(limits = c(12.30897, 12.30973), expand = c(0, 0)) +
  scale_y_continuous(limits = c(51.36527, 51.36638), expand = c(0, 0)) + 
  coord_equal() + 
  labs(title = "TLS Canopy Height Model SD",
       x = "Longitude",
       y = "Latitude",
       fill = "Standard Deviation")
ggsave("../TLS_figures/chm_sd_full_res.png", dpi = 300)

## lower res chm
df_h_tls_top_res <- as.data.frame(h_tls_top_res, xy = TRUE)
colnames(df_h_tls_top_res) <- c("x", "y", "value")

df_h_tls_sd_res <- as.data.frame(h_tls_sd_res, xy = TRUE)
colnames(df_h_tls_sd_res) <- c("x", "y", "value")

ggplot(df_h_tls_top_res, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = custom_palette, limits = c(0, 35)) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 20)) +
  scale_x_continuous(limits = c(12.30897, 12.30973), expand = c(0, 0)) +
  scale_y_continuous(limits = c(51.36527, 51.36638), expand = c(0, 0)) + 
  coord_equal() + 
  labs(title = "TLS Canopy Height Low Res",
       x = "Longitude",
       y = "Latitude",
       fill = "Height")
ggsave("../TLS_figures/chm_height.png", dpi = 300)

ggplot(df_h_tls_sd_res, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = col, limits = c(0, 15)) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 20)) +
  scale_x_continuous(limits = c(12.30897, 12.30973), expand = c(0, 0)) +
  scale_y_continuous(limits = c(51.36527, 51.36638), expand = c(0, 0)) + 
  coord_equal() + 
  labs(title = "TLS Canopy Height Model SD Low Res",
       x = "Longitude",
       y = "Latitude",
       fill = "Standard Deviation")
ggsave("../TLS_figures/chm_sd.png", dpi = 300)

## sentinel
df_h_s2_top <- as.data.frame(h_s2_top, xy = TRUE)
colnames(df_h_s2_top) <- c("x", "y", "value")

df_h_s2_sd <- as.data.frame(h_s2_sd, xy = TRUE)
colnames(df_h_s2_sd) <- c("x", "y", "value")

ggplot(df_h_s2_top, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = custom_palette, limits = c(0, 35)) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 20)) +
  scale_x_continuous(limits = c(12.30897, 12.30973), expand = c(0, 0)) +
  scale_y_continuous(limits = c(51.36527, 51.36638), expand = c(0, 0)) + 
  coord_equal() + 
  labs(title = "Sentinel Canopy Height",
       x = "Longitude",
       y = "Latitude",
       fill = "Height")
ggsave("../TLS_figures/sentinel_height.png", dpi = 300)

ggplot(df_h_s2_sd, aes(x = x, y = y, fill = value)) +
  geom_raster() +
  scale_fill_gradientn(colors = col, limits = c(0, 15)) +
  theme_minimal() +
  theme(legend.position = "bottom", text = element_text(size = 20)) +
  scale_x_continuous(limits = c(12.30897, 12.30973), expand = c(0, 0)) +
  scale_y_continuous(limits = c(51.36527, 51.36638), expand = c(0, 0)) + 
  coord_equal() + 
  labs(title = "Sentinel Canopy Height SD",
       x = "Longitude",
       y = "Latitude",
       fill = "Standard Deviation")
ggsave("../TLS_figures/sentinel_sd.png", dpi = 300)



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