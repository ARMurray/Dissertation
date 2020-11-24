## Script Descriptions

### data_completeness.R
This script checks the completeness of the downloaded SAMP data

### Ease_Grid_Template.R
This script takes an h5 file from SMAP and creates a template polygon layer to use with SMAP data.
This script completely relies on the sf package and does not require the traditional GDAL tools hdf5 conversion method.

### Extract_PRISM_to_Storms.R
This script extracts PRISM data to storms, aggregated by the SMAP cell template.


### Extract_SMAP_Data.R
This script will extract data from SMAP hdf5 files and join it to a spatial template. 
You need to have a template to join them to spatially and a list of h5 files you want
to use. I import my entire folder of h5 files but use a filter to refine my analysis.

### filterStorms.R
This script loads all atlantic cyclone activity and determines which made landfall

### H5_2_GeoTIFF.R
This is another script for conversion from HDF5 but this uses the more standard gdal method

### Merge_NOAA_Storms.R
Merge pount files from all storms into one shapefile

### mosaic_overlapping_rasters.R
This script is used to mosaic rasters created in the 'H5_2_GeoTIFF.R' script.
SMAP images overlap eachother and also have a large number of NA values
In many cases, NA values from one raster overlap real values in another
raster. The function below will mosaic multiple rasters together but in cases
where pixels overlap will default to the higher number. NA values in SMAP come
as '-9999' so this allows NA values to be removed in favor of real values

### stormMapping.R
Create maps of storms