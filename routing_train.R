library(opentripplanner)
library(this.path)
library(sf)
library(dplyr)
setwd(this.dir())
source('utils-otp.R')


setwd(this.dir())
setwd('../DHZW_shapefiles/data/processed/shapefiles')
df_PC6_Moerwijk <- st_read('df_PC6_station_shp')

df_PC6_DHZW <- st_read('PC6_DHZW_shp')

setwd(this.dir())
setwd('data')
df <- read.csv('OD_asymmetric.csv')

# Create the server
otp_setup(otp = path_otp, dir = path_data, memory=10000, port = 8801, securePort = 8802)

# Connect to the server
otpcon <- otp_connect(timezone = Sys.timezone(), port = 8801)

################################################################################

# initialise variables
df$time_total <- NA
df$time_walk <- NA
df$time_transit_bus <- NA
df$time_transit_train <- NA
df$time_waiting <- NA

df$n_changes <- NA

df$distance_total <- NA
df$distance_walk <- -NA
df$distance_bus <- NA
df$distance_train <- NA

df$stop_PC6 <- NA

# only for trips partially outside, and not completely outside
df <- df[(df$departure_in_DHZW==1 & df$arrival_in_DHZW==0) | (df$departure_in_DHZW==0 & df$arrival_in_DHZW==1),]

start_time <- Sys.time()

for (i in 1:nrow(df)){
  timer <- difftime(Sys.time(), start_time, units = "secs")
  print(paste0(round(((i/nrow(df))*100),2), '% - ', timer))
  
  tryCatch({
    
    from <- c(df[i,]$departure_x, df[i,]$departure_y)
    to <- c(df[i,]$arrival_x, df[i,]$arrival_y)
    
    route <- otp_plan(otpcon,
                      fromPlace = from,
                      toPlace = to,
                      mode = c('TRANSIT'),
                      date_time = as.POSIXct(strptime("2023-02-09 08:00", "%Y-%m-%d %H:%M")),
                      arriveBy = FALSE,
    )
    
    # filter only solutions that are actually by train
    route <- route %>% 
      group_by(route_option) %>% 
      filter(any(.data[['leg_mode']] == 'RAIL'))
    
    if(nrow(route)>0) {
      # select the fastest option
      df_fastest_option <- route %>%
        group_by(route_option) %>%
        summarize(min_duration = min(duration))
      
      fastest_option_id <- df_fastest_option$route_option[which.min(df_fastest_option$min_duration)]
      
      route <- route[route$route_option == fastest_option_id,]
    
    
      # filter the faster route
      route <- route %>%
        select(fromPlace, toPlace, duration, walkTime, transitTime, waitingTime, walkDistance, transfers, leg_distance, leg_mode, leg_startTime, leg_route, leg_routeShortName, leg_duration)
      
      df[i,]$time_transit_train <- 0
      df[i,]$distance_train <- 0
      df[i,]$time_transit_bus <- 0
      df[i,]$distance_bus <- 0
      for (x in 1:nrow(route)) {
        if (route[x,]$leg_mode == 'RAIL'){
          df[i,]$time_transit_train <- df[i,]$time_transit_train + round(route[x,]$leg_duration/60, 1)
          df[i,]$distance_train <- df[i,]$distance_train + round(route[x,]$leg_distance/1000, 1)
        } else if (route[x,]$leg_mode == 'BUS' | route[x,]$leg_mode == 'TRAM' | route[x,]$leg_mode == 'SUBWAY') {
          df[i,]$time_transit_bus <- df[i,]$time_transit_bus + round(route[x,]$leg_duration/60, 1)
          df[i,]$distance_bus <- df[i,]$distance_bus + round(route[x,]$leg_distance/1000, 1)
        }
      }
      
      df[i,]$time_total <- round(route[1,]$duration/60, 1) # minutes
      df[i,]$time_walk <- round(route[1,]$walkTime/60, 1)
      
      df[i,]$time_waiting <- round(route[1,]$waitingTime/60, 1)
      
      df[i,]$n_changes <- route[1,]$transfers
      
      df[i,]$distance_total <- round(sum(route$leg_distance)/1000, 1) #km
      df[i,]$distance_walk <- round(route[1,]$walkDistance/1000, 1)
      
      ################################################################################
      
      ########### Section find train station Moerwijk ##########################
      
      legs_train <- route[route$leg_mode=='RAIL',]
      
      # order the legs with the one more inside DHZW first. less computation search then
      if(df[i,]$departure_in_DHZW == 1) {
        legs_train <- legs_train[order(legs_train$leg_startTime),]
      } else {
        legs_train <- legs_train[order(desc(legs_train$leg_startTime)),]
      }
      
      x = 1
      found <- FALSE
      # for each leg
      while(x <= nrow(legs_train) & !found){
        
        # Get the geometry of the current leg
        leg <- legs_train$geometry[x]
        
        # retrieve start and end points of the leg
        point_1 <- lwgeom::st_startpoint(leg)
        point_2 <- lwgeom::st_endpoint(leg)
        
        # Find if there is one of the postcodes of the train station Moerwijk matches with the departure or arrival 
        geometry_point1 <- df_PC6_Moerwijk[st_intersection(df_PC6_Moerwijk$geometry, point_1), ]
        geometry_point2 <- df_PC6_Moerwijk[st_intersection(df_PC6_Moerwijk$geometry, point_2), ]
        
        # if one of the two points matches, the train goes through Moerwijk
        if((nrow(geometry_point1)!=0 & nrow(geometry_point2)==0) | (nrow(geometry_point2)!=0 & nrow(geometry_point1)==0)){
          found = TRUE
        }
        
        x = x + 1
      }
      
      ########### Section find bus stop within DHZW ############################
      
      if (found==TRUE) {
        print('train via Moerwijk')
        df[i,]$stop_PC6 <- '2532CP'
      } else {
        print('no train via Moerwijk. So, I look if at least the individual takes a bus from within DHZW')
        
        legs_bus <- route[route$leg_mode %in% c('BUS', 'TRAM', 'SUBWAY'),]
        
        # order the legs with the one more inside DHZW first. less computation search then
        if(df[i,]$departure_in_DHZW == 1) {
          legs_bus <- legs_bus[order(legs_bus$leg_startTime),]
        } else {
          legs_bus <- legs_bus[order(desc(legs_bus$leg_startTime)),]
        }
        
        x = 1
        found <- FALSE
        # for each leg
        while(x <= nrow(legs_bus) & !found){
          
          # Get the geometry of the current leg
          leg <- legs_bus$geometry[x]
          
          # retrieve start and end points of the leg
          point_1 <- lwgeom::st_startpoint(leg)
          point_2 <- lwgeom::st_endpoint(leg)
          
          # Find if there is a postcode in DHZW that contains that point
          geometry_point1 <- df_PC6_DHZW[st_intersection(df_PC6_DHZW$geometry, point_1), ]
          geometry_point2 <- df_PC6_DHZW[st_intersection(df_PC6_DHZW$geometry, point_2), ]
          
          # if the bus leg crosses outside of DHZW, that leg is the one I am looking for
          if((nrow(geometry_point1)!=0 & nrow(geometry_point2)==0) | (nrow(geometry_point2)!=0 & nrow(geometry_point1)==0)){
            found = TRUE
            
            # take the postcode of the bus stop in DHZW
            if (nrow(geometry_point1)!=0){
              df[i,]$stop_PC6 <- geometry_point1$PC6
            } else {
              df[i,]$stop_PC6 <- geometry_point2$PC6
            }
          }
          
          x = x + 1
        }
        
        if (found==TRUE) {
          print('Individual goes by bus to take the train somewhere else')
          print(postcode_bus_stop)
        } else {
          print('Individual goes by train, but does not take any transport within DHZW')
          df[i,]$stop_PC6 <- 0
        }
        
      }
      
    } else {
      print('Route not feasible by train')
      # there are no routes by bus
      df[i,]$time_total <- -1
      df[i,]$time_walk <- -1
      df[i,]$time_transit_bus <- -1
      df[i,]$time_transit_train <- -1
      df[i,]$time_waiting <- -1
      df[i,]$n_changes <- -1
      df[i,]$distance_total <- -1
      df[i,]$distance_walk <- -1
      df[i,]$distance_bus <- -1
      df[i,]$distance_train <- -1
      df[i,]$stop_PC6 <- -1
    }
    
  }, error = function(e) {
  })
  
}

# add PC5 of bus stop
df$stop_PC5 <- -1
df[!is.na(df$stop_PC6) & df$stop_PC6 != -1 & df$stop_PC6 != 0,]$stop_PC5 <- gsub('.{1}$', '', df[!is.na(df$stop_PC6) & df$stop_PC6 != -1 & df$stop_PC6 != 0,]$stop_PC6)

df[is.na(df$stop_PC6),]$stop_PC6 <- -1

# for the ones that are not even doable by foot
df[is.na(df$time_total),]$time_total <- -1
df[is.na(df$time_walk),]$time_walk <- -1
df[is.na(df$time_transit_bus),]$time_transit_bus <- -1
df[is.na(df$time_transit_train),]$time_transit_train <- -1
df[is.na(df$time_waiting),]$time_waiting <- -1
df[is.na(df$n_changes),]$n_changes <- -1
df[is.na(df$distance_total),]$distance_total <- -1
df[is.na(df$distance_walk),]$distance_walk <- -1
df[is.na(df$distance_bus),]$distance_bus <- -1
df[is.na(df$distance_train),]$distance_train <- -1


# save
setwd(this.dir())
setwd('output')
write.csv(df, paste0('train_routing',Sys.time(),'.csv'), row.names = FALSE)
