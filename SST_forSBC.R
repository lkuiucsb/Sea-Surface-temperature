rm(list = ls())

#-----------------------------------------------------------------------------
#extract temperature data from SST raster file and compile into one datasheet
library(reshape2)
library(dplyr)
library(ncdf4)
library(raster)
library(weathermetrics)
#https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1

#acknowlegement:  Please acknowledge the use of these data with the following statement:  These data were provided by JPL under support by NASA MEaSUREs program.
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#using the date range below as an example
begin_d <- as.Date("2021-01-01") # The start date for this satellite is 2002-06-01. The earlier date is not valide. 
end_d<- as.Date("2021-01-10")

range <- as.integer(end_d-begin_d)

for (i in 1:(range+1)) {
  
  year1 = format(begin_d,format="%Y")
  
  date1 = format(begin_d,format="%Y%m%d") 
  
  doy <- strftime(begin_d, format = "%j")
  
  #download netcdf sst file from podaac server with Santa Barbara region
  input.path <- paste0("https://podaac-opendap.jpl.nasa.gov:443/opendap/allData/ghrsst/data/GDS2/L4/GLOB/JPL/MUR/v4.1/",year1,"/",doy,"/",date1,"090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc.nc4?time[0:1:0],lat[12100:1:12500],lon[5700:1:6300],analysed_sst[0:1:0][12100:1:12500][5700:1:6300]")
  
  write.path <- paste0("data/temperature/",date1,".nc")
  
  download.file(input.path,write.path,quiet=T,method="auto",mode="wb")
  
  
  begin_d <- begin_d+1
  
}

#download is finished. 
#The next step is to extract the sst from the netcdf files for any given coordinates listed in the site table below.
###########################################

#read in a site table with long and lat
site <- read.csv("data/site_tb.csv")

begin_d <- as.Date("2021-01-01") # The start date for this satellite is 2002-06-01. The earlier date is not valide. 
end_d<- as.Date("2021-01-10")

range <- as.integer(end_d-begin_d)

#assign an empty data frame
data1 <- data.frame()

for (i in 1:(range+1)) {
  
  year1 = format(begin_d,format="%Y")
  
  date1 = format(begin_d,format="%Y%m%d") 
  
  ncin <- brick(paste0("data/temperature/",date1,".nc"),varname="analysed_sst")
  
  #dim(ncin)
  #print(ncin)
 
  ex <- raster::extract(ncin, site[,c("longitude","latitude")])
  
  #convert from Kelvin to C
  temp_C <- convert_temperature(ex,"k","c",round=2)
  
  tray <- bind_cols(year=rep(year1,nrow(site)),date=rep(date1,nrow(site)),site_id=site$siteid,temp_C=temp_C) 
  
  data1 <- bind_rows(data1,tray)
  
  begin_d <- begin_d+1
  
}    

#Export
write.csv(data1,"data/Sites_temperature_daily.csv",row.names = F)
