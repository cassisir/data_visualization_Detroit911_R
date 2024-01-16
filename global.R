# install.packages("shiny")
# install.packages("shinydashboard")
# install.packages("leaflet")
# install.packages("plotly")
# install.packages("dplyr")
# install.packages("leaflet.extras")

library(sf)
library(lubridate)
library(sp)
library(data.table)
library(leaflet.extras)
library(shiny)
library(shinydashboard)
library(leaflet)
library(plotly)
library(dplyr)
library(tmap)
library(DT)

# Define a function to extract latitude from the location string
extract_latitude <- function(location) {
  coords <- strsplit(sub("\\)", "", sub(".*\\(", "", location)), ",")
  as.numeric(coords[[1]][1])
}

# Define a function to extract longitude from the location string
extract_longitude <- function(location) {
  coords <- strsplit(sub("\\)", "", sub(".*\\(", "", location)), ",")
  as.numeric(coords[[1]][2])
}

# Define a function to categorize time into time_of_day
time_into_category <- function(timestamp) {
  if (hour(timestamp) >= 5 && hour(timestamp) < 12) {
    return("Morning")
  } else if (hour(timestamp) >= 12 && hour(timestamp) < 18) {
    return("Afternoon")
  } else if (hour(timestamp) >= 18 && hour(timestamp) < 22) {
    return("Evening")
  } else {
    return("Night")
  }
}

# Read the data CSV file
data <- read.csv("dpd_911_calls_for_service.csv")

# Read the GeoJSON file
zipcode_gdf <- st_read("City_of_Detroit_Zip_Codes.geojson")

# Remove duplicates based on 'callno' column
data <- data %>% distinct(callno, .keep_all = TRUE)

# Take absolute values of time-related columns
time_columns <- c('intaketime', 'dispatchtime', 'traveltime', 'totresponsetime', 'timeonscene', 'totaltime')
data[, time_columns] <- abs(data[, time_columns])

# Convert 'calldate' and 'calltime' to datetime
data$calldate <- as.Date(data$calldate, format = "%Y-%m-%d")
data$calltime <- as.POSIXct(data$calltime, format = "%H:%M:%S")

# Sort the data by date and time
data <- data %>% arrange(calldate, calltime) %>% mutate(call_counts = row_number())

# Extract latitude and longitude from the 'location' column
data$latitude  <- sapply(data$location, extract_latitude)
data$longitude <- sapply(data$location, extract_longitude)
data <- data %>% select(-location)

# Map categories to broader categories
category_mapping <- c(
  'DISORDERLY PERSON' = 'Disturbance',
  'INVESTIGATE PERSON' = 'Investigation',
  'ACCIDENT' = 'Accident',
  'PRANK/OTHER' = 'Prank',
  'ASSAULT' = 'Assault',
  'FAMILY TROUBLE' = 'Domestic',
  'TRAFFIC' = 'Traffic',
  'AUTO THEFT' = 'Theft',
  'MEDICAL' = 'Medical',
  'ALARM' = 'Alarm',
  'BURGLARY' = 'Burglary',
  'ROBBERY' = 'Robbery',
  'SA' = 'Sexual Assault',
  'RAPE' = 'Sexual Assault',
  'FIRE' = 'Fire',
  'DRUGS' = 'Drug Related',
  'AR' = 'Arson',
  'LARCENY' = 'Theft',
  'OTHER' = 'Other',
  'TS' = 'Traffic',
  'TI' = 'Traffic',
  'SI' = 'Investigation',
  'T' = 'Traffic',
  '93' = 'Other',
  'W8' = 'Other',
  '31' = 'Other',
  'ANIMAL' = 'Animal',
  'W3' = 'Other',
  'SPECIAL DETAIL' = 'Special Detail',
  '90' = 'Other',
  'TO' = 'Traffic',
  'SS' = 'Special Service',
  'RA' = 'Restricted Area',
  'W5' = 'Other',
  '99' = 'Other'
)

data$category <- recode(data$category, !!!category_mapping)

# Map dispositions to broader dispositions
disposition_mapping <- c(
  'NO PROBLEM FOUND' = 'No problem found',
  'HANDLED BY OTHER' = 'Handled by Other Agency',
  'FALSE ALARM - BUSINESS' = 'False Alarm',
  'FALSE ALARM - RESIDENCE' = 'False Alarm',
  'FALSE ALARM - OTHER' = 'False Alarm',
  'NCF' = 'No Charges Filed',
  'NSA' = 'No Such Address',
  'ADV' = 'Advised',
  'CAN' = 'Call Cancelled',
  'CANCELLED BY CALLER' = 'Call Cancelled',
  'CANCELLED BY DISPATCH' = 'Call Cancelled',
  'DUP' = 'Duplicate Call',
  'UNF' = 'Unfounded',
  'INV - FURTHER ACTION TAKEN' = 'Investigation - Further Action taken',
  'INV - NO FURTHER ACTION' = 'Investigation - No Further Action',
  'REPORT' = 'Report Taken',
  'ARREST' = 'Arrest Made',
  'INV SUSP AND RELEASED' = 'Investigation - Suspect Released',
  'RECOV STOLEN AUTO' = 'Stolen Auto Recovered',
  'DETAIL COMPLETED' = 'Detail Completed',
  'WARNING GIVEN' = 'Warning Issued',
  'TICKET ISSUED' = 'Ticket Issued',
  'NAR' = 'Narcotics Arrest',
  'RCR' = 'Property Recovered',
  'PCP' = 'Peace Officer Complaint',
  'ASSIST' = 'Assistance and Services',
  'TRANSPORT' = 'Assistance and Services',
  'AC1' = 'Assistance and Services',
  'AC2' = 'Assistance and Services',
  'DPS' = 'Assistance and Services',
  'RPP' = 'Assistance and Services',
  'MSG' = 'Unknown or Miscellaneous',
  'UNK' = 'Unknown or Miscellaneous',
  'IMP' = 'Unknown or Miscellaneous',
  'HTX' = 'Unknown or Miscellaneous',
  'AGO' = 'Unknown or Miscellaneous',
  'VRM' = 'Unknown or Miscellaneous',
  'UTC' = 'Unknown or Miscellaneous',
  'AGB' = 'Unknown or Miscellaneous',
  'RAC' = 'Unknown or Miscellaneous',
  'AGR' = 'Unknown or Miscellaneous',
  'PK13' = 'Unknown or Miscellaneous',
  'PKR1' = 'Unknown or Miscellaneous',
  'PKR3' = 'Unknown or Miscellaneous',
  'PKR4' = 'Unknown or Miscellaneous',
  'PKNC' = 'Unknown or Miscellaneous',
  'AFI' = 'Unknown or Miscellaneous'
)

data$disposition <- recode(data$disposition, !!!disposition_mapping)

# Extract day of the week
data$day_of_week <- weekdays(data$calldate)
data$calldate <- as.Date(data$calldate)

# Add a 'time_of_day' variable
data$time_of_day <- sapply(data$calltime, time_into_category)

# Convert 'data' to SpatialPointsDataFrame
coordinates(data) <- c("longitude", "latitude")

data_sf <- st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)
st_crs(data_sf) <- st_crs(zipcode_gdf)

# Perform spatial join with zip code geometries
result <- st_join(data_sf, zipcode_gdf, join = st_within)

# result : dataframe final

