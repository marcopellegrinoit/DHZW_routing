library(opentripplanner)
library(this.path)
library(sf)
setwd(this.dir())
source('utils-otp.R')

# read origin-destination matrix
setwd(this.dir())
setwd('data')
df_symmetric <- read.csv('OD_symmetric.csv')

flag_new = TRUE

if(flag_new) {
  # read old output if already there
  
  setwd(this.dir())
  setwd('output')
  df_walk_old <- read.csv('walk_time_distance.csv')
  df_bike_old <- read.csv('bike_time_distance.csv')
  df_car_old <- read.csv('car_time_distance.csv')
  
  # add unique postcode to filter
  df_walk_old$combined_id <- ifelse(df_walk_old$departure < df_walk_old$arrival,
                                paste(df_walk_old$departure, df_walk_old$arrival, sep="_"),
                                paste(df_walk_old$arrival, df_walk_old$departure, sep="_"))
  df_bike_old$combined_id <- ifelse(df_bike_old$departure < df_bike_old$arrival,
                                    paste(df_bike_old$departure, df_bike_old$arrival, sep="_"),
                                    paste(df_bike_old$arrival, df_bike_old$departure, sep="_"))
  df_car_old$combined_id <- ifelse(df_car_old$departure < df_car_old$arrival,
                                    paste(df_car_old$departure, df_car_old$arrival, sep="_"),
                                    paste(df_car_old$arrival, df_car_old$departure, sep="_"))
  df_symmetric$combined_id <- ifelse(df_symmetric$departure < df_symmetric$arrival,
                                     paste(df_symmetric$departure, df_symmetric$arrival, sep="_"),
                                     paste(df_symmetric$arrival, df_symmetric$departure, sep="_"))
  
  # difference are the new ones to scrape
  df_walk <- anti_join(df_symmetric, df_walk_old, by = c("combined_id"))  
  df_bike <- anti_join(df_symmetric, df_bike_old, by = c("combined_id"))  
  df_car <- anti_join(df_symmetric, df_car_old, by = c("combined_id"))  
} else {
  df_walk <- df_symmetric
  df_bike <- df_symmetric
  df_car <- df_symmetric
}


# Create the server
otp_setup(otp = path_otp, dir = path_data, memory=10000, port = 8801, securePort = 8802)

# Connect to the server
otpcon <- otp_connect(timezone = "Europe/London", port = 8801)

################################################################################
# walk
df_walk <- compute_walk_bike_car(otpcon, df_walk, 'WALK')
df_walk <- df_walk %>%
  select(colnames(df_walk_old))
df_walk <- subset(df_walk, -c('combined_id'))

# add old entries
df_walk <- rbind(df_walk, df_walk_old)

setwd(this.dir())
setwd('output')
write.csv(df_walk, 'walk_time_distance.csv', row.names = FALSE)

# bile
df_bike <- compute_walk_bike_car(otpcon, df_bike, 'BICYCLE')
df_bike <- df_bike %>%
  select(colnames(df_bike_old))
df_bike = subset(df_bike, select=-c(combined_id))

# add old entries
df_bike <- rbind(df_bike, df_bike_old)

setwd(this.dir())
setwd('output')
write.csv(df_bike, 'bike_time_distance.csv', row.names = FALSE)

# car
df_car <- compute_walk_bike_car(otpcon, df_car, 'CAR')

df_car <- df_car %>%
  select(colnames(df_car_old))
df_car = subset(df_car, select=-c(combined_id))

# add old entries
df_car <- rbind(df_car, df_car_old)

setwd(this.dir())
setwd('output')
write.csv(df_car, 'car_time_distance.csv', row.names = FALSE)

otp_stop()

nrow(walk_time_distance[walk_time_distance$departure=='2533B' | walk_time_distance$arrival=='2533B' |
                          walk_time_distance$departure=='2552' | walk_time_distance$arrival=='2552',])

