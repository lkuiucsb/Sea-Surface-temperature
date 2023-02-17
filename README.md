# Sea-Surface-temperature
This is a R script for two tasks: 1. download the daily sst netcdf file from podaac.jpl.nasa.gov; and 2. extract the sst values for given locations' coordinates. 

The available sst data for this particular satelite starts 2002-06-01. It is not valid to choose an earlier start date when you download the data. Other satellites data on the podaac server provide the sst coverage earlier than 2002. 

In this code, the Santa Barbara Channel region in Southern California Bight was selected for downloading the daily sst netcdf files. If you want to download other region, you want to adjust the download lat and lon in line 30. For extracting the temperature reading for site coordinates, SBCLTER three sites and the first 10 dates in 2021 are used as examples in the R script.  

If you run into issue during the download process, there is a chance that the data is missing from the server, such as 2021-02-20 and 2021-02-21. You can go into this link to find whether the data is on the server: https://podaac-opendap.jpl.nasa.gov/opendap/allData/ghrsst/data/GDS2/L4/GLOB/JPL/MUR/v4.1/

For information about the data and data citation, please refer to the website: https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1
