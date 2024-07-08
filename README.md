# Sea-Surface-temperature
This is a R script for two tasks: 1. download the daily sst csv file from ERDDAP server: https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html; and 2. concat the sst values for all locations listed in the site table. 

The available sst data for this particular satelite starts 2002-06-01. It is not valid to choose an earlier start date when you download the data. Other satellites data on the ERDDAP server provide the sst coverage earlier than 2002 but with coarser resolution such as: https://coastwatch.pfeg.noaa.gov/erddap/griddap/ncdcOisst21Agg.html

Make sure you have all the unique site coordiantes listed in the site_tb.csv file in the "data" folder. 

In this code, the Santa Barbara Channel region in Southern California Bight was selected as an example. If you want to download other sites, make sure you have all the unique site coordiantes listed in the site_tb.csv file in the "data" folder.  

For information about the data and data citation, see the summary page on the website: https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html

The earlier version of the code was to download data from https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1. However, the opendap server starts to require a user name and password (EARTHDATA account) to access the data. So we switch to ERDDAP server, which might be changed when updating the next version of the code. 
