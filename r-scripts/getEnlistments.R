#parses enlistments and repositories by project_id

require("XML")
require("RPostgreSQL")

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

#login credentials, options etc. are stored in config.R
source(wd("./r-scripts/config.R"))
source(wd("./r-scripts/getIds.R"))
source(wd("./r-scripts/getCurrentParseLevel.R"))

#TODO: maybe it's better to make the file a function entirely
#and thus not create a new connection to the db
#set up a driver for the database connection
drv <- dbDriver("PostgreSQL")
#database information is grabbed from config.R
con <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)

#if the XML files retrieved from ohloh should be stored on disk for later use
#check wether the directory is already there and otherwise create it
#projectsDir is set in config.R
if(storeXML == TRUE) {
  if(!file.exists(wd(enlistmentsDir))) {
    dir.create(wd(enlistmentsDir), recursive=TRUE)
  }
}

projectIds <- NA
projectIds <- getIds("project_id")[[1]]

currentEnlistmentsParseLevel <- NA
currentEnlistmentsParseLevel <- getCurrentParseLevel("enlistments")
#parsing projects will start at one step above the last parsed one.
currentEnlistmentsParseLevel <- match(currentEnlistmentsParseLevel, projectIds) +1

j <- NA
j <- currentEnlistmentsParseLevel
system.time(
while (j < (apiCalls+currentEnlistmentsParseLevel)) {
  enlistmentsURL <- paste("http://www.ohloh.net/projects/",projectIds[j],"/enlistments.xml?api_key=",apiKey, sep="")
  print(enlistmentsURL)
  
  tmpEnlXML <- NA
  tmpEnlXML <- try(xmlParse(enlistmentsURL))
  
  #whenever the URL could not be parsed because either the project_id or analysis_id
  #was not available ohloh does not count that as an API-access
  #so let's increase the number of calls we will be making by 1
  if(class(tmpEnlXML)[1] == "try-error") {
    j <- j+1
    apiCalls <- apiCalls + 1
    next
  } else {
    if(storeXML == TRUE){
      enlistmentsFileName <- paste(enlistmentsDir, "/enlistments.",projectIds[j],".xml", sep="")
      #saves the retrieved and parsed XML-file in the local directory specified above.
      #This will overwrite(!) existing files
      try(saveXML(tmpEnlXML, file=wd(enlistmentsFileName), compression = 0, ident=TRUE))
    }
    
    #projects can have multiple repos that are returned by the enlistment
    numRepos <- NA
    numRepos <- as.integer(xmlValue(getNodeSet(tmpEnlXML, "/response/items_returned")[[1]]))
    print(numRepos)
    
    if(numRepos > 0) {      
      for (k in 1:numRepos) {
        iterator_enlistmentId <- paste("/response/result/enlistment[",k,"]/id", sep="")
        enlistmentId <- as.integer(xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentId)[[1]]))
        iterator_enlistment <- paste("/response/result/enlistment[",k,"]/repository", sep="")
        iterator_enlistmentRepoId <- paste("/response/result/enlistment[",k,"]/repository/id", sep="")
        iterator_enlistmentType <- paste("/response/result/enlistment[",k,"]/repository/type", sep="")
        iterator_enlistmentUrl <- paste("/response/result/enlistment[",k,"]/repository/url", sep="")
        iterator_enlistmentUsername <- paste("/response/result/enlistment[",k,"]/repository/username", sep="")
        iterator_enlistmentPassword <- paste("/response/result/enlistment[",k,"]/repository/password", sep="")
        iterator_enlistmentLogged_at <- paste("/response/result/enlistment[",k,"]/repository/logged_at", sep="")
        iterator_enlistmentCommits <- paste("/response/result/enlistment[",k,"]/repository/commits", sep="")
        iterator_enlistmentStatus <- paste("/response/result/enlistment[",k,"]/repository/ohloh_job_status", sep="")
        
        tmpRepoId <- NA
        tmpEnlistment_id <- NA
        tmpProject_id <- NA
        tmpType <- NA
        tmpUrl <- NA
        tmpUsername <- NA
        tmpPassword <- NA
        tmpLogged_at <- as.Date(NA)
        tmpCommits <- NA
        tmpOhloh_job_status <- NA
        
        try(tmpRepoId <- as.integer(xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentRepoId)[[1]])))
        try(tmpEnlistment_id <- enlistmentId)
        try(tmpProject_id <- projectIds[j])
        try(tmpType <- xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentType)[[1]]))
        try(tmpUrl <- xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentUrl)[[1]]))	
        try(tmpUsername <- xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentUsername)[[1]]))  
        try(tmpPassword <- xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentPassword)[[1]]))  
        try(tmpLogged_at <- as.Date(xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentLogged_at)[[1]])))
        try(tmpCommits <- as.integer(xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentCommits)[[1]])))
        try(tmpOhloh_job_status <- xmlValue(getNodeSet(tmpEnlXML, iterator_enlistmentStatus)[[1]]))
        
        #use data frames and dbWriteTable because that will simply convert NAs to no entry
        tmpRepoDf <- NA
        tmpEnlDf <- NA
        
        tmpRepoDf <- data.frame(id=tmpRepoId, type=tmpType, url=tmpUrl, username=tmpUsername, password=tmpPassword, logged_at=tmpLogged_at, commits=tmpCommits, ohloh_job_status=tmpOhloh_job_status, stringsAsFactors = FALSE)
        tmpEnlDf <- data.frame(id=tmpEnlistment_id, project_id=tmpProject_id, repository_id=tmpRepoId, stringsAsFactors = FALSE)
        
        #some repositories are shared by multiple enlistments, that case is covered by unique constraint "repositories_pkey"
        try(dbWriteTable(con, "repositories", tmpRepoDf, row.names = F, append = T))
        dbWriteTable(con, "enlistments", tmpEnlDf, row.names = F, append = T)
      }
    }
    j <- j+1
  }
})

#close the connection to avoid orphan connection if running the script multiple times
dbDisconnect(con)