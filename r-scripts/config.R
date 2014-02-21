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
apiCalls <- 990

#in case of a testrun, existing tables are dropped and new ones created
reBuild <- FALSE

#should the script store each XML-file retrieved locally on disk?
storeXML <- TRUE

#parse info on programming languages?
parseLang <- FALSE

#where to store xml-files?
projectsDir <- "data/xml/projects"
activity_factsDir <- "data/xml/activity_facts"
enlistmentsDir <- "data/xml/enlistments"
languagesDir <- "data/xml/languages"