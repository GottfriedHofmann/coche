#grabs general project information from ohloh and saves them to a postgreSQL database
#TODO: ten sets for each request
#opt: saves each set as XML in ./data/xml so further info can be aquired by demand from disk

require("XML")
require("RPostgreSQL")

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

#login credentials etc. are stored in config.R
source(wd("./r-scripts/config.R"))
#this function allows you to find out which project Id on ohloh is the latest
source(wd("./r-scripts/getLatestProjectId.R"))

#set up a driver for the database connection
drv <- dbDriver("PostgreSQL")

#database information is grabbed from config.R
con <- dbConnect(drv, host=dbHost, dbname=dbName, user=dbUser, password=dbPass)

#set up the tables and triggers for the db
source(wd("./r-scripts/setupDb.R"))

#this should need to be run only once
if(parseLang) {
  source(wd("./r-scripts/getLanguagesData.R"))
}

#if the XML files retrieved from ohloh should be stored on disk for later use
#check wether the directory is already there and otherwise create it
#projectsDir is set in config.R
if(storeXML == TRUE) {
  if(!file.exists(wd(projectsDir))) {
    dir.create(wd(projectsDir), recursive=TRUE)
  }
}

currentMaxId <- NA
currentMaxId <- dbGetQuery(con, "SELECT max(id) from projects;")
if (is.na(currentMaxId)) {
  currentMaxId <- 0
} else currentMaxId <- currentMaxId[[1]]
#parsing projects will start at one step above the last parsed one.
currentMaxId <- currentMaxId +1

#stores project information in the database and locally on disk (optional)
#loop runs in steps of 'apiCalls' due to API key restrictions
system.time(
for (i in currentMaxId:(apiCalls+currentMaxId)) {
  actURL <- paste("http://www.ohloh.net/projects/",i,".xml?api_key=",apiKey, sep="")
  print(actURL)
  
  tmpXML <- NA
  tmpXML <- try(xmlParse(actURL))
  
  if(class(tmpXML)[1] != "try-error"){
    if(storeXML == TRUE){
      projectDataFileName <- paste(projectsDir, "/p.",i,".xml", sep="")
      #saves the retrieved and parsed XML-file in the local directory specified above.
      #This will overwrite(!) existing files
      try(saveXML(tmpXML, file=wd(projectDataFileName), compression = 0, ident=TRUE))
    }
    
    iterator_Id <- paste("/response/result/project/id", sep="")
    iterator_Name <- paste("/response/result/project/name", sep="")
    iterator_Url <- paste("/response/result/project/url", sep="")
    iterator_Html_url <- paste("/response/result/project/html_url", sep="")
    iterator_Created_at <- paste("/response/result/project/created_at", sep="")
    iterator_Updated_at <- paste("/response/result/project/updated_at", sep="")
    iterator_Description <- paste("/response/result/project/description", sep="")
    iterator_Homepage_url <- paste("/response/result/project/homepage_url", sep="")
    iterator_Download_url <- paste("/response/result/project/download_url", sep="")
    iterator_Url_name <- paste("/response/result/project/url_name", sep="")
    iterator_User_count <- paste("/response/result/project/user_count", sep="")
    iterator_Average_rating <- paste("/response/result/project/average_rating", sep="")
    iterator_Rating_count <- paste("/response/result/project/rating_count", sep="")
    iterator_Analysis_id <- paste("/response/result/project/analysis_id", sep="")
    
    id <- NA
    name <- NA
    url <- NA
    html_url <- NA
    created_at <- NA
    updated_at <- NA
    description <- NA
    homepage_url <- NA
    download_url <- NA
    url_name <- NA
    user_count <- NA
    average_rating <- NA
    rating_count <- NA
    analysis_id <- NA
    
    #using try around the whole statement so that the objects stay as NA if things fail
    #this way the table cells of the database will simply be filled with nothing in that case
    try(id <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_Id)[[1]])))
    try(name <- xmlValue(getNodeSet(tmpXML, iterator_Name)[[1]]))
    try(url <- xmlValue(getNodeSet(tmpXML, iterator_Url)[[1]]))
    try(html_url <- xmlValue(getNodeSet(tmpXML, iterator_Html_url)[[1]]))
    try(created_at <- as.Date(xmlValue(getNodeSet(tmpXML, iterator_Created_at)[[1]])))
    try(updated_at <- as.Date(xmlValue(getNodeSet(tmpXML, iterator_Updated_at)[[1]])))
    try(description <- xmlValue(getNodeSet(tmpXML, iterator_Description)[[1]]))
    try(homepage_url <- xmlValue(getNodeSet(tmpXML, iterator_Homepage_url)[[1]]))
    try(download_url <- xmlValue(getNodeSet(tmpXML, iterator_Download_url)[[1]]))
    try(url_name <- xmlValue(getNodeSet(tmpXML, iterator_Url_name)[[1]]))
    try(user_count <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_User_count)[[1]])))
    try(average_rating <- as.double(xmlValue(getNodeSet(tmpXML, iterator_Average_rating)[[1]])))
    try(rating_count <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_Rating_count)[[1]])))
    try(analysis_id <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_Analysis_id)[[1]])))
    
    #use a df and dbWriteTable because that will simply convert NAs to no entry
    tmpProjDf <- NA
    tmpProjDf <- data.frame(id=id, name=name, url=url, html_url=html_url, created_at=created_at, updated_at=updated_at, description=description, homepage_url=homepage_url, download_url=download_url, url_name=url_name, user_count=user_count, average_rating=average_rating, rating_count=rating_count, analysis_id=analysis_id)
    #some entries are duplicates because Ohloh seems to add information even for older projects so the chunks change over time.
    try(dbWriteTable(con, "projects", tmpProjDf, row.names = F, append = T))
    
    if (!is.na(analysis_id)) {
      print(paste("Analysis ",analysis_id," found", sep=""))
      
      iterator_AnalysisId <- paste("/response/result/project/analysis/id", sep="")
      iterator_AnalysisUrl <- paste("/response/result/project/analysis/url", sep="")
      iterator_AnalysisProject_id <- paste("/response/result/project/analysis/project_id", sep="")
      iterator_AnalysisUpdated_at <- paste("/response/result/project/analysis/updated_at", sep="")
      iterator_AnalysisLogged_at <- paste("/response/result/project/analysis/logged_at", sep="")
      iterator_AnalysisMin_month <- paste("/response/result/project/analysis/min_month", sep="")
      iterator_AnalysisMax_month <- paste("/response/result/project/analysis/max_month", sep="")
      iterator_AnalysisTwelve_month_contributor_count <- paste("/response/result/project/analysis/twelve_month_contributor_count", sep="")
      iterator_AnalysisTotal_code_lines <- paste("/response/result/project/analysis/total_code_lines", sep="")
      iterator_AnalysisMain_language_id <- paste("/response/result/project/analysis/main_language_id", sep="")
      
      analysisId <- NA
      analysisUrl <- NA
      analysisProject_id <- NA
      analysisUpdated_at <- NA
      analysisLogged_at <- NA
      analysisMin_month <- NA
      analysisMax_month <- NA
      analysisTwelve_month_contributor_count <- NA
      analysisTotal_code_lines <- NA
      analysisMain_language_id <- NA
      
      #using try around the whole statement so that the objects stay as NA if things fail
      #this way the table cells of the database will simply be filled with nothing in that case
      try(analysisId <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_AnalysisId)[[1]])))
      try(analysisProject_id <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_AnalysisProject_id)[[1]])))
      try(analysisUrl <- xmlValue(getNodeSet(tmpXML, iterator_AnalysisUrl)[[1]]))
      try(analysisUpdated_at <- as.Date(xmlValue(getNodeSet(tmpXML, iterator_AnalysisUpdated_at)[[1]])))
      try(analysisLogged_at <- as.Date(xmlValue(getNodeSet(tmpXML, iterator_AnalysisLogged_at)[[1]])))
      try(analysisMin_month <- as.Date(xmlValue(getNodeSet(tmpXML, iterator_AnalysisMin_month)[[1]])))
      try(analysisMax_month <- as.Date(xmlValue(getNodeSet(tmpXML, iterator_AnalysisMax_month)[[1]])))
      try(analysisTwelve_month_contributor_count <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_AnalysisTwelve_month_contributor_count)[[1]])))
      try(analysisTotal_code_lines <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_AnalysisTotal_code_lines)[[1]])))
      try(analysisMain_language_id <- as.integer(xmlValue(getNodeSet(tmpXML, iterator_AnalysisMain_language_id)[[1]])))
      
      #use a df and dbWriteTable because that will simply convert NAs to no entry
      tmpAnalysisDf <- NA
      tmpAnalysisDf <- data.frame(id=analysisId, url=analysisUrl, project_id=analysisProject_id, updated_at=analysisUpdated_at, logged_at=analysisLogged_at, min_month=analysisMin_month, max_month=analysisMax_month, twelve_month_contributor_count=analysisTwelve_month_contributor_count, total_code_lines=analysisTotal_code_lines,  main_language_id=analysisMain_language_id)
      try(dbWriteTable(con, "analysis", tmpAnalysisDf, row.names = F, append = T))      
    }
    
    #use xmlRoot to get the length of subnodes later on
    tmpXMLRoot <- NA
    tmpXMLRoot <- xmlRoot(tmpXML)
    
    tags <- NA
    numTags <- NA
    numTags <- length(tmpXMLRoot[["result"]][["project"]][["tags"]]["tag", all=TRUE])
    
    if (numTags > 0) {
      for (k in 1:numTags) {
        iterator_tag <- paste("/response/result/project/tags/tag[",k,"]", sep="")
        tag <- NA
        tag <- try(xmlValue(getNodeSet(tmpXML, iterator_tag)[[1]]))
        if(class(tag) != "try-error") {
          #normalization is done on DB-side
          tagQuery <- paste("SELECT normalize_tags(",id,", '",tag,"');", sep="")
          dbGetQuery(con, tagQuery)
        }
      }
    }
    
    numLicenses <- NA
    numLicenses <- length(tmpXMLRoot[["result"]][["project"]][["licenses"]]["license", all=TRUE])
    if(numLicenses > 0) {
      for (k in 1:numLicenses) {
        iterator_license_name <- paste("/response/result/project/licenses/license[",k,"]/name", sep="")
        iterator_license_nice_name <- paste("/response/result/project/licenses/license[",k,"]/nice_name", sep="")
        
        license_name <- NA
        license_nice_name <- NA
        
        license_name <- try(xmlValue(getNodeSet(tmpXML, iterator_license_name)[[1]]))
        license_nice_name <- try(xmlValue(getNodeSet(tmpXML, iterator_license_nice_name)[[1]]))
        
        if(class(license_name) != "try-error"){
          #normalization is done on DB-side
          licensesQuery <- paste("SELECT normalize_licenses(",id,", '",license_name,"', '",license_nice_name,"');", sep="")
          dbGetQuery(con, licensesQuery)
          }
        }
      }
    }
  }
)

#close the connection to avoid orphan connection if running the script multiple times
dbDisconnect(con)

#quit(save = "no", status = 0, runLast = FALSE)

