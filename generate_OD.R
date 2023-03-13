library(readr)
library(dplyr)
library(this.path)

setwd(this.dir())
setwd('../DHZW_synthetic_population_to_Sim2APL/output')
df_activities <- read.csv('DHZW_activities_locations.csv')

df_activities$location_id = NA
df_activities[df_activities$in_DHZW ==1,]$location_id <- df_activities[df_activities$in_DHZW ==1,]$PC5
df_activities[df_activities$in_DHZW ==0,]$location_id <- df_activities[df_activities$in_DHZW ==0,]$PC4

# calculate all possible trips origin-destination
df_asymmetric <- df_activities %>%
  select(pid, day_of_week, location_id, longitude, latitude)

df_asymmetric <- df_asymmetric %>% 
  mutate(same_pid = ifelse(pid == lag(pid), 1, 0)) %>% # add flag is the previous person is the same
  mutate(same_day = ifelse(day_of_week == lag(day_of_week), 1, 0)) %>%# add flag is the previous day is the same
  mutate(departure = lag(location_id)) %>% # copy the previous location ID
  mutate(departure_longitude = lag(longitude)) %>%
  mutate(departure_latitude = lag(latitude)) %>%
  filter(same_pid==1 & same_day==1) %>% # filter only cases of same person and day
  rename(arrival = location_id) %>%
  rename(arrival_longitude = longitude) %>%
  rename(arrival_latitude = latitude) %>%
  select(departure, arrival, departure_longitude, departure_latitude, arrival_longitude, arrival_latitude) %>%
  distinct(departure, arrival, .keep_all = TRUE)

# symmetric OD

df_symmetric <- df_asymmetric
df_symmetric$combined_id <- ifelse(df_symmetric$departure < df_symmetric$arrival,
                              paste(df_symmetric$departure, df_symmetric$arrival, sep="_"),
                              paste(df_symmetric$arrival, df_symmetric$departure, sep="_"))

df_symmetric <- df_symmetric[!duplicated(df_symmetric$combined_id), ]
df_symmetric$combined_id <- NULL

################################################################################
# Save

setwd(this.dir())
setwd('data')
write.csv(df_symmetric, 'OD_symmetric.csv', row.names = FALSE)
write.csv(df_asymmetric, 'OD_asymmetric.csv', row.names = FALSE)
