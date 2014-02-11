## Coche - The Offline Cache for Ohloh.net data

Coche is a set of scripts written in R to access data from [ohloh.net](http://www.ohloh.net) through ohloh's [public REST API](https://github.com/blackducksw/ohloh_api) and store it in a PostgreSQL database. The output XML files can optionally be stored locally as well. Currently it is designed to parse complete sets of data.

### Requirements

Coche has been tested with R version 3.0.x.

The R-scripts can be run seperately and only require the packages [XML](http://cran.r-project.org/web/packages/XML/index.html) and [RPostgreSQL](http://cran.r-project.org/web/packages/RPostgreSQL/index.html). 

You can install the required packages in an R-shell with 

        install.packages(c("XML", "RPostgreSQL2"), dependencies=T)
        
To run coche, an [API key from ohloh](http://www.ohloh.com/accounts/me/api_keys/new) is required.

### Configuration

Configuration is stored in [config.R](r-scripts/config.R). Insert your API key and database credentials here.

Coche uses it's own concept of working directories that is independent from where the script is executed. For every script you want to run set up the *wd()* function you can find at the top of the script.

### Usage

Simply run the R-script for the data you want to parse. Since coche is setting up a schema with foreign keys, you need to parse project info before anything else, though.
