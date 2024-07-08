rm(list = ls())

#-----------------------------------------------------------------------------
#extract temperature data satellite and compile into one data table
library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#we used to download data from https://podaac.jpl.nasa.gov/dataset/MUR-JPL-L4-GLOB-v4.1
#However, the opendap server right now requires a user name and password (EARTHDATA account) to access the data.
# csv was download from address below
#download address:
#https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html

# so this version we shift the download to ERDDAP server, which is open to public.
#The data is the same, but the link is different.


#The data is the MUR SST data from JPL, which is a daily global SST data from 2002 to present.
#The data is in netcdf format, and we will extract the SST data for the Santa Barbara Channel region.

#read in a site table with lon and lat and siteid columns. 
#Because the data has spatial resolution of 0.01 degree, we create a 0.01 degree box around the each of the coordinates to extract the data.
#This will give us a SST data with approximately 1 km radials buffer for each location
sitetb <- read.csv("data/site_tb.csv") %>%
  mutate(min_lon = longitude - 0.01,
         max_lon = longitude + 0.01,
         min_lat = latitude - 0.01,
         max_lat = latitude + 0.01)


#using the date range below as an example
# note that ERDDAP sometimes will download one more day of data, end_d+1, to make sure data cover the time spam you ask for. 
begin_d <- as.Date("2024-01-01") # The start date for this satellite is 2002-06-01. The earlier date is not valid. 
end_d<- as.Date("2024-01-10") # the data updated daily, so the end date can be today's date.

base_url <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.csv"

#show txt progress bar to monitor the download process
prog.bar <- txtProgressBar(min=0, max=(nrow(sitetb)), style=3)

#a loop to download the daily csv files from the ERDDAP server, one loop for one siteid.
for (i in 1:nrow(sitetb)) {
  
  #site id
  site <- sitetb$siteid[i]
  
  # Construct the full URL with the appropriate query parameters
  full_url <- paste0(base_url, "?analysed_sst",
                     "[(", begin_d,"T00:00:00Z", "):1:(", end_d,"T23:59:59Z", ")]",
                     "[(", sitetb$min_lat[i], "):1:(", sitetb$max_lat[i], ")]",
                     "[(", sitetb$min_lon[i], "):1:(", sitetb$max_lon[i], ")]")
  
  #specify where the file will be downloaded to in your local folder, make sure you have a "data" folder with "temperature" subfolder in your working directory 
  write.path <- paste0("data/temperature/",site,".csv")
  
  #download the file and save to the local folder
  download.file(full_url,write.path,quiet=T,method="auto",mode="wb")
  
  #show the progress bar
  setTxtProgressBar(prog.bar, i) 
}

#download is finished. 
#The next step is to concat the sst csv files for all sites.
###########################################

# Specify the folder containing the CSV files
folder_path <- "data/temperature/"

# Get a list of all CSV files in the folder
file_list <- list.files(path = folder_path, pattern = "*.csv", full.names = TRUE)

# Function to read a CSV file and add a column with the file name
read_and_label_csv <- function(file) {
  cname <- read.csv(file,nrow=0)
  df <- read.csv(file, na.strings = "NaN",skip=2)
  
  colnames(df) <- colnames(cname)
  
  df$siteid <- gsub(".csv", "", basename(file))
  return(df)
}

# Read each CSV file and store them in a list
df_list <- lapply(file_list, read_and_label_csv)

# Concatenate all data frames into one
final_df <- bind_rows(df_list)

#Export
write.csv(final_df,"data/Sites_temperature_daily.csv",row.names = F,na="NaN")
