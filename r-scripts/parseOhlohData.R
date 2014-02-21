require("XML")
require("RPostgreSQL")

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

source(wd("./r-scripts/config.R"))

#set up a driver for the database connection
drv <- dbDriver("PostgreSQL")
#database credentials are stored in config.R
con <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)

#finds out which project Id on ohloh is the latest
#note: broken due to bug in ohloh, not used atm
#you need to find out the maximum project id manually from ohloh.net
#source(wd("./r-scripts/getLatestProjectId.R"))

source(wd("./r-scripts/setupDb.R"))
source(wd("./r-scripts/getLanguagesData.R"))
source(wd("./r-scripts/getProjectData.R"))
source(wd("./r-scripts/getActivityFacts.R"))
source(wd("./r-scripts/getEnlistments.R"))

sessionApiCalls <- apiCalls

parseRange <- c(1:20)

#if the tables in the database don't exist yet, create the complete schema
#reBuild=T will drop all tables and create empty ones, set this in config.R 
setupDb(reBuild, parseLang)

#when data on programming languages needs to be parsed,
#getLanguagesData needs to be run before anything else.
#this will cost 12 API calls and should be run only once.
if(parseLang) {
  sessionApiCalls <- getLanguagesData(sessionApiCalls)
  parseLang <- F
}

dbDisconnect(con)

while(TRUE) {
  con <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)
  sessionApiCalls <- getProjectData(parseRange, sessionApiCalls)
  if(sessionApiCalls == 0) {
    dbDisconnect(con)
    print("API call limit exceeded for this session.")
    print("Waiting 24 hours before continuing")
    print(paste("Current time: ",Sys.time(), sep=""))
    Sys.sleep(86400)
    sessionApiCalls <- apiCalls
    next
  }
  
  sessionApiCalls <- getActivityFacts(parseRange, sessionApiCalls)
  if(sessionApiCalls == 0) {
    dbDisconnect(con)
    print("API call limit exceeded for this session.")
    print("Waiting 24 hours before continuing")
    print(paste("Current time: ",Sys.time(), sep=""))
    Sys.sleep(86400)
    sessionApiCalls <- apiCalls
    next
  }
  
  sessionApiCalls <- getEnlistments(parseRange, sessionApiCalls)
  if(sessionApiCalls == 0) {
    dbDisconnect(con)
    print("API call limit exceeded for this session.")
    print("Waiting 24 hours before continuing")
    print(paste("Current time: ",Sys.time(), sep=""))
    Sys.sleep(86400)
    sessionApiCalls <- apiCalls
    next
  }
  
  dbDisconnect(con)
  break
}
