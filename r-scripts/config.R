#this script file stores login credentials and other info that is user-dependent

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

#The range of projects you want to get information for in project_id format
#If you want to parse info on just a specific project, set it for example to c(123)
parseRange <- c(1:10)

#drops tables and creates new ones
reBuild <- FALSE

#parse info on programming languages?
parseLang <- FALSE

#should the script store each XML-file retrieved locally on disk?
storeXML <- TRUE

#where to store xml-files?
projectsDir <- "data/xml/projects"
activity_factsDir <- "data/xml/activity_facts"
enlistmentsDir <- "data/xml/enlistments"
languagesDir <- "data/xml/languages"