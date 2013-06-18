#parses activity facts from given analysis_ids
#TODO: parsing by project_id

require("XML")
require("RPostgreSQL")

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

#login credentials, options etc. are stored in config.R
source(wd("./r-scripts/config.R"))

#TODO: maybe it's better to make the file a function entirely
#and thus not create a new connection to the db
#set up a driver for the database connection
drvAct <- dbDriver("PostgreSQL")
#database information is grabbed from config.R
conAct <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)


#TODO: extend function once more data sources are implemented (like data frames)
getAnalysisIds <- function() {
  analysisIdsWithNAs <- NA
  analysisIdsTmp <- NA
  #analysisIds <- data.frame('analysis_id')
  analysisIdQuery <- paste("SELECT id, analysis_id FROM projects;", sep="")
  analysisIdsWithNAs <- dbGetQuery(conAct, analysisIdQuery)
  analysisIdsTmp <- na.omit(analysisIdsWithNAs)
  #return analysisIds as vector instead of DF inside of DF
  return(analysisIdsTmp)
}

analysisIds <- NA
analysisIds <- getAnalysisIds()

currentParseLevel <- NA
currentParseLevel <- getCurrentParseLevel("analysis_id")
#parsing projects will start at one step above the last parsed one.
currentParseLevel <- currentParseLevel +1

#stores activity_facts in the database and locally on disk (optional)
#loop runs in steps of 'apiCalls' due to API key restrictions
j <- currentParseLevel
system.time(
while (j < (apiCalls+currentMaxId)) {
  activityURL <- paste("https://www.ohloh.net/p/",analysisIds[[1]][j],"/analyses/",analysisIds[[2]][j],"/activity_facts.xml?api_key=",apiKey, sep="")
  print(activityURL)
  
  j <- j+1
}

