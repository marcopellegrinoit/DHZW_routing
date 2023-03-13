library(opentripplanner)
library(this.path)
library(sf)
setwd(this.dir())
source('utils-otp.R')

setwd(this.dir())
setwd('data')
df_symmetric <- read.csv('OD_symmetric.csv')

# Create the server
otp_setup(otp = path_otp, dir = path_data, memory=10000, port = 8801, securePort = 8802)

# Connect to the server
otpcon <- otp_connect(timezone = "Europe/London", port = 8801)

mode = 'BICYCLE'

df_symmetric$travel_time_walk <- NA

start_time <- Sys.time()

for (i in 1:nrow(df_symmetric)){
  timer <- difftime(Sys.time(), start_time, units = "secs")
  print(paste0(round(((i/nrow(df_symmetric))*100),2), '% - ', timer))
  
  if (df_symmetric[i,]$departure == df_symmetric[i,]$arrival) {
    df_symmetric[i,]$travel_time_walk <- 0
  } else {
    from <- c(df_symmetric[i,]$departure_longitude, df_symmetric[i,]$departure_latitude)
    to <- c(df_symmetric[i,]$arrival_longitude, df_symmetric[i,]$arrival_latitude)
  
    df_symmetric[i,]$travel_time_walk <- get_travel_time(otpcon, from, to, mode)
  }
}


otp_stop()