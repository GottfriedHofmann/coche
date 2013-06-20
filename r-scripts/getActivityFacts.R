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

source(wd("./r-scripts/getCurrentParseLevel.R"))

#TODO: maybe it's better to make the file a function entirely
#and thus not create a new connection to the db
#set up a driver for the database connection
drv <- dbDriver("PostgreSQL")
#database information is grabbed from config.R
con <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)

#TODO: extend function once more data sources are implemented (like data frames)
getAnalysisIds <- function() {
  analysisIdsWithNAs <- NA
  analysisIdsTmp <- NA
  #analysisIds <- data.frame('analysis_id')
  analysisIdQuery <- paste("SELECT id, analysis_id FROM projects;", sep="")
  analysisIdsWithNAs <- dbGetQuery(con, analysisIdQuery)
  analysisIdsTmp <- na.omit(analysisIdsWithNAs)
  #return analysisIds as vector instead of DF inside of DF
  return(analysisIdsTmp)
}

#if the XML files retrieved from ohloh should be stored on disk for later use
#check wether the directory is already there and otherwise create it
#projectsDir is set in config.R
if(storeXML == TRUE) {
  if(!file.exists(wd(activity_factsDir))) {
    dir.create(wd(activity_factsDir), recursive=TRUE)
  }
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
uniqueId <- currentParseLevel
system.time(
while (j < (apiCalls+currentMaxId)) {
  activityURL <- paste("http://www.ohloh.net/p/",analysisIds[[1]][j],"/analyses/",analysisIds[[2]][j],"/activity_facts.xml?api_key=",apiKey, sep="")
  print(activityURL)
  
  tmpActXML <- NA
  tmpActXML <- try(xmlParse(activityURL))
  
  #whenever the URL could not be parsed because either the project_id or analysis_id
  #was not available ohloh does not count that as an API-access
  #so let's increase the number of calls we will be making by 1
  if(class(tmpActXML)[1] == "try-error") {
    j <- j+1
    apiCalls <- apiCalls + 1
    next
  } else {
    if(storeXML == TRUE){
      activity_factsFileName <- paste(activity_factsDir, "/activity_fact.",analysisIds[[2]][j],".xml", sep="")
      #saves the retrieved and parsed XML-file in the local directory specified above.
      #This will overwrite(!) existing files
      try(saveXML(tmpActXML, file=wd(activity_factsFileName), compression = 0, ident=TRUE))
    }
    
    #dbWriteTable does not allow empty columns even if the column is a serial so let's create the primary key ourselfs
    numFacts <- as.integer(xmlValue(getNodeSet(tmpActXML, "/response/items_available")[[1]]))
    uniqueOld <- uniqueId
    uniqueId <- uniqueId + numFacts
    
    tmp <- NA
    
    try(tmp <- xmlToDataFrame(tmpActXML, c("character", "integer", "integer", "integer", "integer", "integer", "integer", "integer", "integer"), nodes=getNodeSet(tmpActXML, "//activity_fact")))
    try(tmp[['month']] <- as.Date(tmp[['month']]))
    try(tmp[['contributors']] <- as.factor(tmp[['contributors']]))
    try(tmp[['analysis_id']] <- analysisIds[[2]][j])
    try(tmp[['id']] <- c((uniqueOld+1):uniqueId))
    
    dbWriteTable(con, "activity_facts", tmp, row.names = F, append = T)
  }
  
  j <- j+1
}

