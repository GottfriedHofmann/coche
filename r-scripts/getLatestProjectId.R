#this function returns the id of the project added to ohloh most recently
#that is the maximum project Id on ohloh at the given time
#it is intended for use with the other functions in coche
#that's why it requires data from config.R but does not source it
#use this function by "sourcing" it in other files

### This function returns an arbitrary value atm. due to a possible bug in the ohloh API!

require(XML)

getLatestProjectId <- function() {
  latestId <- NA
  apiCall <- NA
  tmpXML <- NA
  nodeLatestId <- NA
  
  apiCall <- try(paste("http://www.ohloh.net/p.xml?api_key=",apiKey,"&sort=id_reverse", sep=""))
  
  if(class(apiCall) == "try-error") {
    return("Could not set up the API call, maybe config.R is not in the workspace?")
  }
  
  tmpXML <- try(xmlParse(apiCall, isURL=TRUE))
  
  if(class(tmpXML)[1] == "try-error") {
    return("Parsing of XML file failed")
  }
  
  nodeLatestId <- paste("/response/result/project[1]/id")  
  latestId <- try(as.integer(xmlValue(getNodeSet(tmpXML, nodeLatestId)[[1]])))
  
  if(class(latestId) == "try-error") {
    return("Could not get the desired node")
  }
  
  return(latestId)
}