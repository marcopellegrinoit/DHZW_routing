library(readr)
library(dplyr)
library(this.path)

setwd(this.dir())
setwd('../DHZW_synthetic_population_to_Sim2APL/output')
df_activities <- read.csv('DHZW_activities_locations.csv')

# calculate all possible trips origin-destination
df_activities <- df_activities %>%
  select(pid, day_of_week, postcode, coordinate_y, coordinate_x, in_DHZW)

df_trips <- df_activities %>% 
  mutate(same_pid = ifelse(pid == lag(pid), 1, 0)) %>% # add flag is the previous person is the same
  mutate(same_day = ifelse(day_of_week == lag(day_of_week), 1, 0)) %>%# add flag is the previous day is the same
  mutate(departure = lag(postcode)) %>% # copy the previous location ID
  mutate(departure_y = lag(coordinate_y)) %>%
  mutate(departure_x = lag(coordinate_x)) %>%
  mutate(departure_in_DHZW = lag(in_DHZW)) %>%
  filter(same_pid==1 & same_day==1) %>% # filter only cases of same person and day
  rename(arrival = postcode) %>%
  rename(arrival_y = coordinate_y) %>%
  rename(arrival_x = coordinate_x) %>%
  rename(arrival_in_DHZW = in_DHZW) %>%
  select(departure, arrival, departure_y, departure_x, arrival_y, arrival_x, departure_in_DHZW, arrival_in_DHZW) %>%
  filter(!(departure_in_DHZW==arrival_in_DHZW)) %>% # only trips that go outside or come back
  distinct(departure, arrival, .keep_all = TRUE)

################################################################################
# All possible combinations of trips inside DHZW

setwd(this.dir())
setwd('../DHZW_shapefiles/data/processed/csv')
df_PC5 <- read.csv('centroids_PC5_DHZW.csv')

# generate combinations
df_combinations_inside <- expand.grid(df_PC5$PC5, df_PC5$PC5)
colnames(df_combinations_inside) <- c('departure', 'arrival')

# remove same PC5
df_combinations_inside <- df_combinations_inside[df_combinations_inside$departure != df_combinations_inside$arrival,]

# add coordinates
df_combinations_inside <- merge(df_combinations_inside, df_PC5, by.x = 'departure', by.y = 'PC5')
df_combinations_inside <- df_combinations_inside %>%
  rename(departure_y = coordinate_y,
         departure_x = coordinate_x)

df_combinations_inside <- merge(df_combinations_inside, df_PC5, by.x = 'arrival', by.y = 'PC5')
df_combinations_inside <- df_combinations_inside %>%
  rename(arrival_y = coordinate_y,
         arrival_x = coordinate_x)

df_combinations_inside$departure_in_DHZW <- 1
df_combinations_inside$arrival_in_DHZW <- 1
  
df_asymmetric  <- rbind(df_trips, df_combinations_inside)

################################################################################
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
