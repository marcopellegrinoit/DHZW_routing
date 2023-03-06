# library(opentripplanner)
# library(this.path)
# library(sf)
# setwd(this.dir())
# 
# path_data = this.dir()
# path_otp <- paste0(path_data, '/otp-2.2.0-shaded.jar')

"greeting"

# #get_travel_time <- function () {
#   # Connect R to the server
#   otpcon <- otp_connect(timezone = "Europe/London", port = 8801)
#   
#   from <- c(4.30518, 52.06850)
#   to <- c(4.30738, 52.06929)
#   
#   route <- otp_plan(otpcon, 
#                     fromPlace = from, 
#                     toPlace = to,
#                     mode = 'WALK')
#   route$duration
# #}