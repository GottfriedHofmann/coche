#parses activity facts from given analysis_ids
#TODO: parsing by project_id, returning the activity facts of the latest analysis

# ### the following part can be un-commented if you want to run the script directly
# require("XML")
# require("RPostgreSQL")
# 
# #function to set a working directory for the project
# wd <- function(Dir) {
#   return(paste("~/git-repositories/coche/",Dir,sep=""))
# }
# 
# #login credentials, options etc. are stored in config.R
# source(wd("./r-scripts/config.R"))
# 
# #set up a driver for the database connection
# drv <- dbDriver("PostgreSQL")
# #database information is grabbed from config.R
# con <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)
# ###

#stores activity_facts in the database and locally on disk (optional)
#loop runs in steps of 'sessionApiCalls' due to API key restrictions
getActivityFacts <- function(parseRange, sessionApiCalls) {

source(wd("./r-scripts/getCurrentParseLevel.R"))
source(wd("./r-scripts/getIds.R"))

#if the XML files retrieved from ohloh should be stored on disk for later use
#check wether the directory is already there and otherwise create it
#projectsDir is set in config.R
if(storeXML == TRUE) {
  if(!file.exists(wd(activity_factsDir))) {
    dir.create(wd(activity_factsDir), recursive=TRUE)
  }
}

analysisIds <- NA
analysisIds <- getIds("analysis_id")
activityFactsProjectIds <- NA
activityFactsProjectIds <- getIds("activity_facts_project_id")

toParse <- intersect(parseRange, analysisIds[[1]])
try(toParse <- setdiff(toParse, activityFactsProjectIds[[1]]))
toParse <- sort(toParse)

currentParseLevel <- NA
currentParseLevel <- getCurrentParseLevel("analysis_id")
#parsing projects will start at one step above the last parsed one.
currentParseLevel <- currentParseLevel +1


#j <- currentParseLevel
#j <- min(toParse)
j <- 1

uniqueId <- NA
uniqueId <- getCurrentParseLevel("count_analysis_id")
uniqueId <- uniqueId +1

while ((j <= length(toParse)) && (sessionApiCalls > 0)) {
  projectId <- NA
  projectId <- toParse[[j]]
  analysisId <- NA
  analysisId <- analysisIds[which(analysisIds[[1]] == projectId),][[2]]
  activityURL <- paste("http://www.ohloh.net/p/",projectId,"/analyses/",analysisId,"/activity_facts.xml?api_key=",apiKey, sep="")
  print(activityURL)
  
  tmpActXML <- NA
  tmpActXML <- try(xmlParse(activityURL))
  
  #whenever the URL could not be parsed because either the project_id or analysis_id
  #was not available ohloh does not count that as an API-access
  #so let's increase the number of calls we will be making by 1
  if(class(tmpActXML)[1] == "try-error") {
    j <- j+1
    #sessionApiCalls <- sessionApiCalls + 1
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
    try(tmp[['project_id']] <- projectId)
    try(tmp[['id']] <- c((uniqueOld+1):uniqueId))
    
    
    dbWriteTable(con, "activity_facts", tmp, row.names = F, append = T)
  }
  
  j <- j+1
  sessionApiCalls <- sessionApiCalls-1
}

return(sessionApiCalls)

}

#close the connection to avoid orphan connection if running the script multiple times
#dbDisconnect(con)
