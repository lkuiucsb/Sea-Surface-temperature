rm(list = ls())

#-----------------------------------------------------------------------------
#extract temperature data satellite and compile into one data table
library(tidyverse)
library(httr)

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
end_d<- as.Date("2024-03-15") # the data updated daily, so the end date can be today's date.

base_url <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.csv"

#show txt progress bar to monitor the download process
prog.bar <- txtProgressBar(min=0, max=(nrow(sitetb)), style=3)

# ensure output folder exists
if (!dir.exists("data/temperature")) dir.create("data/temperature", recursive = TRUE)

# improved safe downloader: returns TRUE on success, retries with exponential backoff for retryable HTTP codes
safe_download <- function(url, dest, retries = 5, timeout_sec = 240) {
  for (attempt in seq_len(retries)) {
    res <- try(
      httr::GET(
        url,
        httr::user_agent("R (httr)"),
        httr::write_disk(dest, overwrite = TRUE),
        httr::timeout(timeout_sec)
      ),
      silent = TRUE
    )
    if (inherits(res, "try-error")) {
      if (attempt < retries) {
        Sys.sleep(2 ^ attempt)
        next
      } else stop("Download error: ", url)
    }
    code <- httr::status_code(res)
    if (code >= 200 && code < 300) return(invisible(TRUE))
    # retry transient server / rate-limit responses
    if (code %in% c(408, 429, 500, 502, 503, 504) && attempt < retries) {
      Sys.sleep(2 ^ attempt)
      next
    }
    stop("Failed to download: ", url, " (HTTP ", code, ")")
  }
}

# replace single large-request loop with chunked downloads (monthly by default)
chunk_by <- "month" # use "week" if month chunks still time out

for (i in seq_len(nrow(sitetb))) {
  site <- sitetb$siteid[i]
  month_starts <- seq(begin_d, end_d, by = chunk_by)
  # ensure final chunk endpoint covers end_d
  month_starts <- unique(c(month_starts, end_d + 1))
  for (m in seq_len(length(month_starts) - 1)) {
    chunk_start <- month_starts[m]
    chunk_end <- pmin(end_d, month_starts[m + 1] - 1)
    # build ERDDAP query with explicit YYYY-MM-DD formatting
    full_url <- paste0(
      base_url, "?analysed_sst",
      "[(", format(chunk_start, "%Y-%m-%d"), "T00:00:00Z):1:(",
      format(chunk_end, "%Y-%m-%d"), "T23:59:59Z)]",
      "[(", sitetb$min_lat[i], "):1:(", sitetb$max_lat[i], ")]",
      "[(", sitetb$min_lon[i], "):1:(", sitetb$max_lon[i], ")]"
    )
    write.path <- file.path("data", "temperature",
                            paste0(site, "_", format(chunk_start, "%Y%m%d"), "-", format(chunk_end, "%Y%m%d"), ".csv"))

 # attempt download but don't abort entire run on single-chunk failure
    tryCatch(
      safe_download(full_url, write.path, retries = 5, timeout_sec = 240),
      error = function(e) {
        message("Warning: chunk failed for ", site, " ", format(chunk_start), " to ", format(chunk_end), " -- ", e$message)
      }
    )
  }
  setTxtProgressBar(prog.bar, i)
}
close(prog.bar)

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
  
  bn <- tools::file_path_sans_ext(basename(file))

  df$siteid <- strsplit(bn, "_")[[1]][1]
  return(df)
}

# Read each CSV file and store them in a list
df_list <- lapply(file_list, read_and_label_csv)

# Concatenate all data frames into one
final_df <- bind_rows(df_list)

#Export
write.csv(final_df,"data/Sites_temperature_daily.csv",row.names = F,na="NaN")
