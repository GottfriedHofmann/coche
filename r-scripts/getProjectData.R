#grabs general project information from ohloh
#ten sets for each request
#saves each set as XML in ./data/xml so further info can be aquired by demand from disk

require(XML)

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

#login credentials etc. are stored in config.R
source(wd("./r-scripts/config.R"))

numToParse <- 20000

#load the previously aquired data or create empty data structures
list_project_name <- list()
try(load(wd("./data/list_project_name.RData")))

df_project_name <- data.frame()
try(load(wd("./data/df_project_name.RData")))

list_project_licenses <- list()
try(load(wd("./data/list_project_licenses.RData")))

df_project_licenses <- data.frame()
try(load(wd("./data/df_project_licenses.RData")))

#stores project information in lists of dataframes and dataframes
#the name list stores dataframes of 10 projects each because each request returns 10 projects
#loop runs in steps of x due to API key restrictions
for (i in (length(list_project_name)+1):(length(list_project_name)+numToParse)) {
  actURL <- paste("http://www.ohloh.net/p.xml?api_key=",apiKey,"&sort=id&page=",i, sep="")
  print(actURL)
  
  tmp <- NA
  
  try(tmp <- xmlParse(actURL, isURL=TRUE))
  
  projectDataFileName <- paste("./data/xml/projects/p.page",i,".xml", sep="")
  
  try(saveXML(tmp, file=wd(projectDataFileName), compression = 0, ident=TRUE))
  
  #try(project_list[[i]] <- xmlParse(actURL, isURL=TRUE))
  
  #if(!is.na(project_list[[i]])){
  if(!is.na(tmp)){
    try(tmp_projectName <- xmlToDataFrame(tmp, nodes=getNodeSet(tmp, "//project"), stringsAsFactors =  FALSE))
    
    #only id and name are of interest here
    tmp_projectName <-tmp_projectName[c(1,2)]
    
    #coerce to int and chr
    #print(tmp_projectName[[1]])
    tmp_projectName[[1]] <- as.integer(tmp_projectName[[1]])
    #print(tmp_projectName[[2]])
    tmp_projectName[[2]] <- as.character(tmp_projectName[[2]])
    
    #add the temporary df to the list
    list_project_name[[i]] <- tmp_projectName
    
    for (i in 1:10) {
      iterator_Licenses <- paste("/response/result/project[",i,"]/licenses//license", sep="")
      iterator_Id <- paste("/response/result/project[",i,"]/id", sep="")
      id <- as.integer(xmlValue(getNodeSet(tmp, iterator_Id)[[1]]))
      #print(id)
      tmpDf <- xmlToDataFrame(tmp, nodes=getNodeSet(tmp, iterator_Licenses), stringsAsFactors =  FALSE)
      #print(tmpDf)
      try(tmpDf[['project_id']] <- id)
      #print(tmpDf)
      list_project_licenses[[id]] <- tmpDf
      }
    
    #df_projects <- try(rbind(df_projects, project_list[[i]]))
    } else {
      #in theory this case should never occur
      list_project_name[[i]] <- NA
    }
}

#create a df from the list data
system.time(df_project_name <- do.call(rbind, list_project_name))

system.time(df_project_licenses <- do.call(rbind, list_project_licenses))

str(df_project_name)
str(df_project_licenses)

save(list_project_name, file=wd("./data/list_project_name.RData"))
save(df_project_name, file=wd("./data/df_project_name.RData"))

save(list_project_licenses, file=wd("./data/list_project_licenses.RData"))
save(df_project_licenses, file=wd("./data/df_project_licenses.RData"))


quit(save = "no", status = 0, runLast = FALSE)

