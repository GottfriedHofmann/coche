## Coche - The Offline Cache for Ohloh.net data

Coche is a set of scripts written in R to access project data from [ohloh.net](http://www.ohloh.net) through ohloh's [public REST API](https://github.com/blackducksw/ohloh_api) and store it in a PostgreSQL database. The output XML files can optionally be stored locally as well. Currently it is designed to parse ranges of data (for example projects with id 1 to 100). Selecting individual projects is possible by setting the range to just the projects of interest.
### Requirements

Coche has been tested with R version 3.0.x.

The R-scripts can be run seperately and only require the packages [XML](http://cran.r-project.org/web/packages/XML/index.html) and [RPostgreSQL](http://cran.r-project.org/web/packages/RPostgreSQL/index.html). 

You can install the required packages in an R-shell with 

        install.packages(c("XML", "RPostgreSQL2"), dependencies=T)
        
To run coche, an [API key from ohloh](http://www.ohloh.com/accounts/me/api_keys/new) is required.

### Configuration

Configuration is stored in [config.R](r-scripts/config.R). Set your API key, database credentials and global options there.

Coche uses it's own concept of working directories that is independent from where the script is executed. Before you can use any of the parsing functions set up the *wd()* function you can find at the top of the script [parseOhlohData.R](r-scripts/parseOhlohData.R).

### Usage

The example script [parseOhlohData.R](r-scripts/parseOhlohData.R) should provide you with all information you need. Since coche is setting up a schema with foreign keys, you either need to parse project info before anything else or remove the foreign key restrictions from [setupDb.R](r-scripts/setupDb.R).
