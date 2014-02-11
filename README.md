## Coche - The Offline Cache for Ohloh.net data

Coche is a set of scripts written in R to access data from [ohloh.net](http://www.ohloh.net) through ohloh's [public REST API](https://github.com/blackducksw/ohloh_api) and store it in a PostgreSQL database. The output XML files can optionally be stored locally as well.

### Requirements

Coche has been tested with R version 3.0.x.

The R-scripts can be run seperately and only require the packages [XML](http://cran.r-project.org/web/packages/XML/index.html) and [RPostgreSQL](http://cran.r-project.org/web/packages/RPostgreSQL/index.html). 

You can install the required packages in an R-shell with 

        install.packages(c("XML", "RPostgreSQL2"), dependencies=T)
        
To run coche, an [API key from ohloh](http://www.ohloh.com/accounts/me/api_keys/new) is required.

### Configuration

Configuration is stored in config.R. Insert your API key and database credentials here.
