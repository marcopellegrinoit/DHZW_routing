path_data = paste0(this.dir(),'/otp')
path_otp <- paste0(path_data, '/otp-2.2.0-shaded.jar')

compute_walk_bike_car <- function(otpcon, df, mode) {
  df$travel_time <- NA
  df$distance <- NA
  
  start_time <- Sys.time()
  for (i in 1:nrow(df)){
    timer <- difftime(Sys.time(), start_time, units = "secs")
    print(paste0(round(((i/nrow(df))*100),2), '% - ', timer))
    
    if (df[i,]$departure == df[i,]$arrival) {
      df[i,]$travel_time <- 0  # do not compute if departure == destination
      df[i,]$distance <- 0
    } else {
      from <- c(df[i,]$departure_x, df[i,]$departure_y)
      to <- c(df[i,]$arrival_x, df[i,]$arrival_y)
      
      tryCatch({
        route <- otp_plan(otpcon,
                          fromPlace = from,
                          toPlace = to,
                          mode = mode,
                          date_time = as.POSIXct(strptime("2023-03-06 17:00", "%Y-%m-%d %H:%M")))
        
        travel_time <- route$duration/60 # minutes
        
        distance <- route$leg_distance/1000 #km
        
        df[i,]$travel_time <- travel_time
        df[i,]$distance <- distance
      }, error = function(e) {
      })
    }
  }
  
  df[is.na(df$travel_time),]$travel_time <- -1
  df[is.na(df$distance),]$distance <- -1
  return(df)
}
