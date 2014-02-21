#Parses general info of programming languages 
#should only be run when there is already a connection for the database
#and config.R is alread loaded

getLanguagesData <- function(sessionApiCalls) {

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
  iterator_Status <- paste("/response/status", sep="")
  iterator_Items_returned <- paste("/response/items_returned", sep="")
  iterator_Items_available <- paste("/response/items_available", sep="")
  
  status <- NA
  status <- try(xmlValue(getNodeSet(tmpLangXML, iterator_Status)[[1]]))
  if(class(status)!="try-error" && status == "success") {
    items_returned <- NA
    items_available <- NA
    
    try(items_returned <- as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_Items_returned)[[1]])))
    try(items_available <- as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_Items_available)[[1]])))
    
    langLoops <- NA
    langLoops <- ceiling(items_available/items_returned)
    
    print(status)
    
    #TODO: this wastes 1 API-Call, find way to save it
    for(i in 1:langLoops) {
      langURL <- paste("http://www.ohloh.net/languages.xml?page=",i,"&api_key=",apiKey, sep="")
      print(langURL)
      tmpLangXML <- NA
      tmpLangXML <- try(xmlParse(langURL))
      if(class(tmpLangXML)[1] != "try-error") {
        if(storeXML == TRUE){
          languagesDataFileName <- paste(languagesDir, "/l.",i,".xml", sep="")
          #saves the retrieved and parsed XML-file in the local directory specified above.
          #This will overwrite(!) existing files
          try(saveXML(tmpLangXML, file=wd(languagesDataFileName), compression = 0, ident=TRUE))
        }
        items_returned <- NA
        items_returned <- try(as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_Items_returned)[[1]])))
        if(class(items_returned) != "try-error" && items_returned > 0) {
          for(j in 1:items_returned) {
            iterator_langId <- paste("/response/result/language[",j,"]/id", sep="")
            iterator_langName <- paste("/response/result/language[",j,"]/name", sep="")
            iterator_langNice_name <- paste("/response/result/language[",j,"]/nice_name", sep="")
            iterator_langCategory <- paste("/response/result/language[",j,"]/category", sep="")
            iterator_langCode <- paste("/response/result/language[",j,"]/code", sep="")
            iterator_langComments <- paste("/response/result/language[",j,"]/comments", sep="")
            iterator_langBlanks <- paste("/response/result/language[",j,"]/blanks", sep="")
            iterator_langComment_ratio <- paste("/response/result/language[",j,"]/comment_ratio", sep="")
            iterator_langProjects <- paste("/response/result/language[",j,"]/projects", sep="")
            iterator_langContributors <- paste("/response/result/language[",j,"]/contributors", sep="")
            iterator_langCommits <- paste("/response/result/language[",j,"]/contributors", sep="")
            
            langId <- NA
            langName <- NA
            langNice_name <- NA
            langCategory <- NA
            langCode <- NA
            langComments <- NA
            langBlanks <- NA
            langComment_ratio <- NA
            langProjects <- NA
            langContributors <- NA
            langCommits <- NA
            
            #using try around the whole statement so that the objects stay as NA if things fail
            #this way the table cells of the database will simply be filled with nothing in that case
            try(langId <- as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_langId)[[1]])))
            try(langName <- xmlValue(getNodeSet(tmpLangXML, iterator_langName)[[1]]))
            try(langNice_name <- xmlValue(getNodeSet(tmpLangXML, iterator_langNice_name)[[1]]))
            try(langCategory <- xmlValue(getNodeSet(tmpLangXML, iterator_langCategory)[[1]]))
            try(langCode <- as.numeric(xmlValue(getNodeSet(tmpLangXML, iterator_langCode)[[1]])))
            try(langComments <- as.numeric(xmlValue(getNodeSet(tmpLangXML, iterator_langComments)[[1]])))
            try(langBlanks <- as.numeric(xmlValue(getNodeSet(tmpLangXML, iterator_langBlanks)[[1]])))
            try(langComment_ratio <- as.double(xmlValue(getNodeSet(tmpLangXML, iterator_langComment_ratio)[[1]])))
            try(langProjects <- as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_langProjects)[[1]])))
            try(langContributors <- as.integer(xmlValue(getNodeSet(tmpLangXML, iterator_langContributors)[[1]])))
            try(langCommits <- as.numeric(xmlValue(getNodeSet(tmpLangXML, iterator_langCommits)[[1]])))          
            
            #TODO: Maybe multiple rows can be stored at once outside the loop?
            languagesQuery <- paste("INSERT INTO languages(id, name, nice_name, category, code, comments, blanks, comment_ratio, projects, contributors, commits) VALUES('",langId,"', '",langName,"', '",langNice_name,"', '",langCategory,"', '",langCode,"', '",langComments,"', '",langBlanks,"', '",langComment_ratio,"', '",langProjects,"', '",langContributors,"', '",langCommits,"')", sep="")
            dbGetQuery(con, languagesQuery)
          }
        }      
      }
    }
    #since some API calls have been used we need to remove those from the global variable that defines how many are left
    sessionApiCalls <- sessionApiCalls - langLoops - 1
    return(sessionApiCalls)
  }
}

}
  
  