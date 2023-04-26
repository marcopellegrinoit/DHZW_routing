library(opentripplanner)
library(this.path)
library(sf)
library(dplyr)
setwd(this.dir())
source('utils-otp.R')

setwd(this.dir())
setwd('data')
df <- read.csv('OD_asymmetric.csv')

setwd(this.dir())
setwd('../DHZW_shapefiles/data/processed/shapefiles')
df_PC6_DHZW <- st_read('PC6_DHZW_shp')

# Create the server
#otp_setup(otp = path_otp, dir = path_data, memory=10000, port = 8801, securePort = 8802)

# Connect to the server
otpcon <- otp_connect(timezone = Sys.timezone(), port = 8801)

################################################################################

# initialise variables
df$time_total <- NA
df$time_walk <- NA
df$time_transit <- NA
df$time_waiting <- NA

df$n_changes <- NA

df$distance_total <- NA
df$distance_walk <- -NA
df$distance_transit <- NA

df$stop_PC6 <- NA

calculate <- function (df) {
  
  for (i in 1:nrow(df)){
    print(round(((i/nrow(df))*100),2))
    
    tryCatch({
      
      from <- c(df[i,]$departure_x, df[i,]$departure_y)
      to <- c(df[i,]$arrival_x, df[i,]$arrival_y)
      
      route <- otp_plan(otpcon,
                        fromPlace = from,
                        toPlace = to,
                        mode = c('WALK', 'BUS', 'TRAM', 'SUBWAY'),
                        date_time = as.POSIXct(strptime("2023-02-09 08:00", "%Y-%m-%d %H:%M")),
                        arriveBy = FALSE,
      )
      
      # check if there are at least two rows. if it was only foot, there would be only one row
      if(nrow(route) > 1) {
        # filter out routes that are only by foot
        route <- route[route$walkTime != route$duration,]
        
        # select the fastest option
        df_fastest_option <- route %>%
          group_by(route_option) %>%
          summarize(min_duration = min(duration))
        
        fastest_option_id <- df_fastest_option$route_option[which.min(df_fastest_option$min_duration)]
        
        route <- route[route$route_option == fastest_option_id,]
        
        # filter the faster route
        route <- route %>%
          select(fromPlace, toPlace, duration, walkTime, transitTime, waitingTime, walkDistance, transfers, leg_distance, leg_mode, leg_startTime, leg_route, leg_routeShortName)
        
        df[i,]$time_total <- round(route[1,]$duration/60, 1) # minutes
        df[i,]$time_walk <- round(route[1,]$walkTime/60, 1)
        df[i,]$time_transit <- round(route[1,]$transitTime/60, 1)
        df[i,]$time_waiting <- round(route[1,]$waitingTime/60, 1)
        
        df[i,]$n_changes <- route[1,]$transfers
        
        df[i,]$distance_total <- round(sum(route$leg_distance)/1000, 1) #km
        df[i,]$distance_walk <- round(route[1,]$walkDistance/1000, 1)
        df[i,]$distance_transit <- df[i,]$distance_total - df[i,]$distance_walk
        
        ################################################################################
        
        # if the trip is partially outside
        if(df[i,]$departure_in_DHZW !=  df[i,]$arrival_in_DHZW){
          legs_bus <- route[route$leg_mode!='WALK',]
          
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
                postcode_bus_stop <- geometry_point1$PC6
              } else {
                postcode_bus_stop <- geometry_point2$PC6
              }
            }
            
            x = x + 1
          }
          
          if (found==TRUE) {
            print('found')
            print(postcode_bus_stop)
            df[i,]$stop_PC6 <- postcode_bus_stop
          } else {
            print('no bus taken from DHZW')
            df[i,]$stop_PC6 <- -1
          }
        }
        
      } else {
        # there are no routes by bus
        df[i,]$time_total <- -1
        df[i,]$time_walk <- -1
        df[i,]$time_transit <- -1
        df[i,]$time_waiting <- -1
        df[i,]$n_changes <- -1
        df[i,]$distance_total <- -1
        df[i,]$distance_walk <- -1
        df[i,]$distance_transit <- -1
        df[i,]$stop_PC6 <- -1
      }
      
    }, error = function(e) {
    })
    
  }
  
  return(df)
}


setwd(this.dir())
setwd('output')


df_1 <- df[1:5000,]
df_1 <- calculate(df_1)
nrow(df_1[is.na(df_1),])
write.csv(df_1, 'df_1.csv', row.names = FALSE)

df_2 <- df[5001:10000,]
df_2 <- calculate(df_2)
nrow(df_2[is.na(df_2),])
write.csv(df_2, 'df_2.csv', row.names = FALSE)

df_3 <- df[10001:15000,] 
df_3 <- calculate(df_3)
nrow(df_3[is.na(df_3),])
write.csv(df_3, 'df_3.csv', row.names = FALSE)

df_4 <- df[15001:20000,] 
df_4 <- calculate(df_4)
nrow(df_4[is.na(df_4),])
write.csv(df_4, 'df_4.csv', row.names = FALSE)

df_5 <- df[20001:nrow(df),] 
df_5 <- calculate(df_5)
nrow(df_5[is.na(df_5),])
write.csv(df_5, 'df_5.csv', row.names = FALSE)

df <- rbind(df_1,
            df_2,
            df_3,
            df_4,
            df_5)

df$stop_PC5 <- '-1'
df[!is.na(df$stop_PC6) & df$stop_PC6 != -1 & df$stop_PC6 != 0,]$stop_PC5 <- gsub('.{1}$', '', df[!is.na(df$stop_PC6) & df$stop_PC6 != -1 & df$stop_PC6 != 0,]$stop_PC6)
df[is.na(df$stop_PC6),]$stop_PC6 <- '-1'

# for the ones that are not even doable by foot
df[is.na(df$time_total),]$time_total <- -1
df[is.na(df$time_walk),]$time_walk <- -1
df[is.na(df$time_transit),]$time_transit <- -1
df[is.na(df$time_waiting),]$time_waiting <- -1
df[is.na(df$n_changes),]$n_changes <- -1
df[is.na(df$distance_total),]$distance_total <- -1
df[is.na(df$distance_walk),]$distance_walk <- -1
df[is.na(df$distance_transit),]$distance_transit <- -1

df$feasible <- 1
df[df$time_total==-1,]$feasible <- -1

# save
setwd(this.dir())
setwd('output')
write.csv(df, 'routing_bus.csv', row.names = FALSE)