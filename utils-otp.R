library(opentripplanner)

path_data = this.dir()
path_otp <- paste0(path_data, '/otp-2.2.0-shaded.jar')
  
get_travel_time <- function (otpcon, from, to, mode) {
  # Connect R to the server
  otpcon <- otp_connect(timezone = "Europe/London", port = 8801)
  
  from = c(4.250288, 52.04648)
  to = c(4.470929, 52.00237)
  
 
  route <- otp_plan(otpcon,
                    fromPlace = from,
                    toPlace = to,
                    mode = mode)
  
  return(route$duration/60)
}