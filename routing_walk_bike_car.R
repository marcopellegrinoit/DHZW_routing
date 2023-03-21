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

################################################################################
# walk
df_walk <- df_symmetric
df_walk <- compute_walk_bike_car(otpcon, df_walk, 'WALK')

setwd(this.dir())
setwd('output')
write.csv(df_walk, 'walk_time_distance.csv', row.names = FALSE)

# bile
df_bike <- df_symmetric
df_bike <- compute_walk_bike_car(otpcon, df_bike, 'BICYCLE')

setwd(this.dir())
setwd('output')
write.csv(df_bike, 'bike_time_distance.csv', row.names = FALSE)

# car
df_car <- df_symmetric
df_car <- compute_walk_bike_car(otpcon, df_car, 'CAR')

setwd(this.dir())
setwd('output')
write.csv(df_car, 'car_time_distance.csv', row.names = FALSE)

otp_stop()

nrow(walk_time_distance[walk_time_distance$departure=='2533B' | walk_time_distance$arrival=='2533B' |
                          walk_time_distance$departure=='2552' | walk_time_distance$arrival=='2552',])

