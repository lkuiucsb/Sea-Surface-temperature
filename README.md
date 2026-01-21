# Sea-Surface-temperature
This is a R script for two tasks: 1. download the daily sst csv file from ERDDAP server: https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html; and 2. concat the sst values for all locations listed in the site table. 

Note: downloads are performed in monthly chunks by default to avoid ERDDAP timeouts and rate-limit issues. The script uses `chunk_by = "month"` when building requests; you can switch to `"week"` if shorter chunks are needed for reliability.

The available sst data for this particular satelite starts 2002-06-01. It is not valid to choose an earlier start date when you download the data. Other satellites data on the ERDDAP server provide the sst coverage earlier than 2002 but with coarser resolution such as: https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst21Agg.html

Fill in `data/site_tb.csv` with one row per site including `siteid`, `longitude`, and `latitude`. The script uses these coordinates and extracts SST within a 0.01° box around each coordinate. Ensure `siteid` values are unique.

For information about the data and data citation, see the summary page on the website: https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html

The earlier version of the code was to download data from https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1. However, the opendap server starts to require a user name and password (EARTHDATA account) to access the data. So we switch to ERDDAP server, which might be changed when updating the next version of the code. 
