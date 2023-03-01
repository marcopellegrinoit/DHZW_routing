library(opentripplanner)
library(this.path)
library(sf)
setwd(this.dir())

path_data = this.dir()
path_otp <- paste0(path_data, '/otp-2.2.0-shaded.jar')

otp_check_java(otp_version = 2.2)

otp_build_graph(otp = path_otp,
                dir = path_data,
                memory = 12000)