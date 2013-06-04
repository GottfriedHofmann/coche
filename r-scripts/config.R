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
apiCalls <- 1000

#in case of a testrun, existing tables are dropped and new ones created
testRun <- TRUE

#should the script store each XML-file retrieved locally on disk?
storeXML <- TRUE

#where to store xml-files for projects?
projectsDir <- "data/xml/projects"

#where to store xml-files for languages?
languagesDir <- "data/xml/languages"

#parse info on programming languages?
parseLang <- TRUE