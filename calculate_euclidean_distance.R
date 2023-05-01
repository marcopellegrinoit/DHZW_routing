library(opentripplanner)
library(this.path)
library(sf)
library(dplyr)
setwd(this.dir())
library(geosphere)

setwd(this.dir())
setwd('data')
df <- read.csv('OD_symmetric.csv')

df$distance_km <- round(distHaversine(df[, c("departure_x", "departure_y")], 
                                df[, c("arrival_x", "arrival_y")]) / 1000, 1)

df <- df %>%
  select(departure, arrival, distance_km)

setwd(this.dir())
setwd('output')
write.csv(df, 'beeline_distance.csv', row.names = FALSE)
