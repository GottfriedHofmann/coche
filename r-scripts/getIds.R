#returns list of ids from various sources
#TODO: extend function once more data sources are implemented (like data frames)

getIds <- function(idType) {
  idsWithNAs <- NA
  idsTmp <- NA
  if(idType == "analysis_id") {
    idQuery <- paste("SELECT id, analysis_id FROM projects ORDER BY id;", sep="")
  } else if (idType == "project_id") {
    idQuery <- paste("SELECT id FROM projects ORDER BY id;", sep="")
  } else if (idType == "activity_facts_project_id") {
    idQuery <- paste("SELECT DISTINCT project_id FROM activity_facts ORDER BY project_id;", sep="")
  } else if (idType == "enlistments_project_id") {
    idQuery <- paste("SELECT DISTINCT project_id FROM enlistments ORDER BY project_id;", sep="")
  } else {
    print("specified idType not supported")
    return(NA)
  }
  idsWithNAs <- dbGetQuery(con, idQuery)
  idsTmp <- na.omit(idsWithNAs)
  return(idsTmp)
}