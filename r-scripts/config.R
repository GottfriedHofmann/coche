#this script file stores login credentials and other info is is user-dependent

#ohloh API-Key
apiKey <- ""

#hostname of your databse
dbHost <- ""

#name database
dbName <- ""

#username database
dbUser <- ""

#password database
dbPass <- ""

#number of ohloh API calls per day, set a little lower than the actual amount
#for example if you can make 1000 calls per day, set it to 990 
apiCalls <- 20

#should the script store each XML-file retrieved locally on disk?
storeXML <- TRUE

#where should the xml-files be stored?
projectsDir <- "data/xml/projects"