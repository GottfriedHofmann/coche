#grabs general project information from ohloh and saves them to a postgreSQL database
#ten sets for each request
#saves each set as XML in ./data/xml so further info can be aquired by demand from disk

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

#at the moment this drops existing tables for testing purposes
if(dbExistsTable(con, "projects")) {
  dbRemoveTable(con, "projects")
  dbSendQuery(con, "CREATE TABLE projects (id integer primary key, name varchar(40), url text, html_url text, created_at date, updated_at date, description text, homepage_url text, download_url text, url_name text, user_count integer, average_rating double precision, rating_count integer, analysis_id integer);")
} else {
  dbSendQuery(con, "CREATE TABLE projects (id integer primary key, name varchar(40), url text, html_url text, created_at date, updated_at date, description text, homepage_url text, download_url text, url_name text, user_count integer, average_rating double precision, rating_count integer, analysis_id integer);")
}

if(dbExistsTable(con, "project_licenses")) {
  dbRemoveTable(con, "project_licenses")
  dbSendQuery(con, "CREATE TABLE project_licenses (id serial primary key, project_id integer, license_id integer);")
} else {
  dbSendQuery(con, "CREATE TABLE project_licenses (id serial primary key, project_id integer, license_id integer);")
}

if(dbExistsTable(con, "licenses")) {
  dbRemoveTable(con, "licenses")
  dbSendQuery(con, "CREATE TABLE licenses (name varchar(40), nice_name text, id serial primary key);")
} else {
  dbSendQuery(con, "CREATE TABLE licenses (name varchar(40), nice_name text, id serial primary key);")
}

#if the XML files retrieved from ohloh should be stored on disk for later use
#check wether the directory is already there and otherwise create it
#projectsDir is set in config.R
if(storeXML == TRUE) {
  if(!file.exists(wd(projectsDir))) {
    dir.create(wd(projectsDir), recursive=TRUE)
  }
}

#stores project information in the database
#the temporary XML structure stores 10 projects each because each request returns 10 projects
#loop runs in steps of 'numToParse' due to API key restrictions
for (i in 1:apiCalls) {
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
    
    j <- 1
    
    iterator_Id <- paste("/response/result/project[",j,"]/id", sep="")
    iterator_Name <- paste("/response/result/project[",j,"]/name", sep="")
    iterator_Url <- paste("/response/result/project[",j,"]/url", sep="")
    iterator_Html_url <- paste("/response/result/project[",j,"]/html_url", sep="")
    iterator_Created_at <- paste("/response/result/project[",j,"]/created_at", sep="")
    iterator_Updated_at <- paste("/response/result/project[",j,"]/updated_at", sep="")
    iterator_Description <- paste("/response/result/project[",j,"]/description", sep="")
    iterator_Homepage_url <- paste("/response/result/project[",j,"]/homepage_url", sep="")
    iterator_Download_url <- paste("/response/result/project[",j,"]/download_url", sep="")
    iterator_Url_name <- paste("/response/result/project[",j,"]/url_name", sep="")
    iterator_User_count <- paste("/response/result/project[",j,"]/user_count", sep="")
    iterator_Average_rating <- paste("/response/result/project[",j,"]/average_rating", sep="")
    iterator_Rating_count <- paste("/response/result/project[",j,"]/rating_count", sep="")
    iterator_Analysis_id <- paste("/response/result/project[",j,"]/analysis_id", sep="")
    
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
    
    tmpProjDf <- NA
    tmpProjDf <- data.frame(id=id, name=name, url=url, html_url=html_url, created_at=created_at, updated_at=updated_at, description=description, homepage_url=homepage_url, download_url=download_url, url_name=url_name, user_count=user_count, average_rating=average_rating, rating_count=rating_count, analysis_id=analysis_id)
    #some entries are duplicates because Ohloh seems to add information even for older projects so the chunks change over time.
    try(dbWriteTable(con, "projects", tmpProjDf, row.names = F, append = T))
    
    tmpLicenses <- NA
    numLicenses <- NA
    #use xmlRoot to get the length of subnodes later on
    #maybe this step can be done earlier?
    tmpLicenses <- xmlRoot(tmpXML)
    numLicenses <- length(tmpLicenses[["result"]][["project"]][["licenses"]]["license", all=TRUE])
    if(numLicenses > 0) {
      for (k in 1:length(tmpLicenses[["result"]][["project"]][["licenses"]]["license", all=TRUE])) {
	iterator_license_name <- paste("/response/result/project[",j,"]/licenses/license[",k,"]/name", sep="")
	iterator_license_nice_name <- paste("/response/result/project[",j,"]/licenses/license[",k,"]/nice_name", sep="")
	
	license_name <- NA
	license_nice_name <- NA
	
	license_name <- try(xmlValue(getNodeSet(tmpXML, iterator_license_name)[[1]]))
	license_nice_name <- try(xmlValue(getNodeSet(tmpXML, iterator_license_nice_name)[[1]]))
	
	if(class(license_name) != "try-error"){
	  licenseQuery <- NA
	  licenseQuery <- paste("INSERT INTO licenses(name, nice_name) VALUES('",license_name,"','",license_nice_name,"')", sep="")
	  dbGetQuery(con, licenseQuery)
	}
      }
    }
  } 
}




quit(save = "no", status = 0, runLast = FALSE)

