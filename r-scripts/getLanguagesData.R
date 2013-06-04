#Parses general info of programming languages 
#should only be run when there is already a connection for the database
#and config.R is alread loaded

require("RPostgreSQL")

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

#if the XML files retrieved from ohloh should be stored on disk for later use
#check wether the directory is already there and otherwise create it
#projectsDir is set in config.R
if(storeXML == TRUE) {
  if(!file.exists(wd(languagesDir))) {
    dir.create(wd(languagesDir), recursive=TRUE)
  }
}

#stores general language information in the database and locally on disk (optional)
langURL <- paste("http://www.ohloh.net/languages.xml?page=1&api_key=",apiKey, sep="")
print(langURL)
tmpLangXML <- NA
tmpLangXML <- try(xmlParse(langURL))
if(class(tmpLangXML)[1] != "try-error"){
  iterator_Items_returned <- paste("/response/items_returned", sep="")
  iterator_Items_available <- paste("/response/items_available", sep="")
  
  items_returned <- NA
  items_available <- NA
  
  try(items_returned <- as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_Items_returned)[[1]])))
  try(items_available <- xmlValue(getNodeSet(tmpLangXML, iterator_Items_available)[[1]]))
  
  print(items_returned)
  print(items_available)
}