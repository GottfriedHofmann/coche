#returns the level up to which ohloh data sets have been parsed
#for project_ids it returns the maximum project_id in the projects table
#for activity_facts it returns the number of rows in the activity_facts table
#TODO: currently it is possible for analysises to stay in the db even
#      in the case of the analysis being replaced by a newer one

getCurrentParseLevel <- function(idType) {
  parseLevelQuery <- NA
  currentMaxId <- NA
  if (idType == "project_id") {
    parseLevelQuery <- paste("SELECT max(id) from projects;")
  } else if (idType == "enlistments") {
    parseLevelQuery <- paste("SELECT max(project_id) from enlistments;")
  } else if (idType == "analysis_id") {
    parseLevelQuery <- paste("SELECT count(a) FROM (SELECT DISTINCT analysis_id AS a FROM activity_facts) AS analysis_unique;")
  } else if (idType == "count_analysis_id") {
    parseLevelQuery <- paste("SELECT count(analysis_id) FROM activity_facts;")
  } else {
    print("specified idType not supported")
    return(NA)
  }
  
  currentMaxId <- dbGetQuery(con, parseLevelQuery)
  if (is.na(currentMaxId)) {
    currentMaxId <- 0
  } else currentMaxId <- currentMaxId[[1]]
  
  return(currentMaxId)
}
