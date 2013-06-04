#Set up tables and triggers for the database
#should only be run when there is already a connection for the database
#and config.R is alread loaded

require("RPostgreSQL")

#function to set a working directory for the project
wd <- function(Dir) {
  return(paste("~/git-repositories/coche/",Dir,sep=""))
}

#set up the database table structure
#if testRun is set to TRUE, drop old tables and create new ones
projectsCreateTableQuery <- paste("CREATE TABLE projects (id integer primary key, name varchar(40), url text, html_url text, created_at date, updated_at date, description text, homepage_url text, download_url text, url_name text, user_count integer, average_rating double precision, rating_count integer, analysis_id integer);")
if(dbExistsTable(con, "projects") && testRun) {   
  dbSendQuery(con, "DROP TABLE projects CASCADE;")
  dbSendQuery(con, projectsCreateTableQuery)
} else {
  dbSendQuery(con, projectsCreateTableQuery)
}

tagsCreateTableQuery <- paste("CREATE TABLE tags (id serial primary key, tag text UNIQUE);")
if(dbExistsTable(con, "tags") && testRun) {
  dbSendQuery(con, "DROP TABLE tags;")
  dbSendQuery(con, tagsCreateTableQuery)
} else {
  dbSendQuery(con, tagsCreateTableQuery)
}

#new setup for project_tags to work with a trigger for auto-normalization
#project_tagsCreateTableQuery <- paste("CREATE TABLE project_tags (project_id integer references projects (id), tag_id integer references tags (id), id serial primary key);")
project_tagsCreateTableQuery <- paste("CREATE TABLE project_tags (project_id integer references projects (id), tag_id text, id serial primary key);")
if(dbExistsTable(con, "project_tags") && testRun) {
  dbSendQuery(con, "DROP TABLE project_tags;")
  dbSendQuery(con, project_tagsCreateTableQuery)
} else {
  dbSendQuery(con, project_tagsCreateTableQuery)
}

analysisCreateTableQuery <- paste("CREATE TABLE analysis (id integer primary key, project_id integer references projects (id), updated_at date, logged_at date, min_month date, max_month date, twelve_month_contributor_count integer, total_code_lines integer, main_language_id integer);")
if(dbExistsTable(con, "analysis") && testRun) {
  dbSendQuery(con, "DROP TABLE analysis CASCADE;")
  dbSendQuery(con, analysisCreateTableQuery)
} else {
  dbSendQuery(con, analysisCreateTableQuery)
}

licensesCreateTableQuery <- paste("CREATE TABLE licenses (name varchar(40) UNIQUE, nice_name text, id serial primary key);")
if(dbExistsTable(con, "licenses") && testRun) {
  dbSendQuery(con, "DROP TABLE licenses CASCADE;")
  dbSendQuery(con, licensesCreateTableQuery)
} else {
  dbSendQuery(con, licensesCreateTableQuery)
}

project_licensesCreateTableQuery <- paste("CREATE TABLE project_licenses (id serial primary key, project_id integer references projects (id), license_id integer references licenses (id) );")
if(dbExistsTable(con, "project_licenses") && testRun) {
  dbSendQuery(con, "DROP TABLE project_licenses;")
  dbSendQuery(con, project_licensesCreateTableQuery)
} else {
  dbSendQuery(con, project_licensesCreateTableQuery)
}

#only run if the parsing of language info is enabled
#TODO: category can have only 3 values, is there s.th. like factor in R for pgSQL?
languagesCreateTableQuery <- paste("CREATE TABLE languages (id integer primary key, name varchar(40), nice_name text, category varchar(40), code integer, comments integer, blanks integer, comment_ratio float, projects integer, contributors integer, commits integer);")
if(dbExistsTable(con, "languages") && testRun && parseLang) {
  dbSendQuery(con, "DROP TABLE languages;")
  dbSendQuery(con, languagesCreateTableQuery)
} else {
  dbSendQuery(con, languagesCreateTableQuery)
}

#create a trigger on the DB to auto-normalize (note: this is still kind of a hack since tag_id needs to be text instead of integer)
project_tagsTriggerQuery <- paste("CREATE OR REPLACE FUNCTION normalize_tags() RETURNS TRIGGER AS $$
                                  DECLARE
                                  foo int := 0;
                                  BEGIN
                                  IF (SELECT NEW.tag_id ~ '^[0-9]+$') THEN
                                  RETURN NEW;
                                  
                                  END IF;
                                  foo := (SELECT id FROM tags WHERE tag = NEW.tag_id);
                                  IF foo != 0 THEN
                                  -- IF NEW.tag_id IN (SELECT tag AS tmpTag FROM tags) THEN
                                  NEW.tag_id := foo;
                                  RETURN NEW;
                                  END IF;
                                  -- ELSE
                                  INSERT INTO tags (tag) VALUES (NEW.tag_id);
                                  NEW.tag_id := (SELECT id AS tagId FROM tags WHERE tag =  NEW.tag_id);
                                  RETURN NEW;
                                  -- END IF;
                                  END;
                                  $$ LANGUAGE plpgsql;
                                  
                                  CREATE TRIGGER tagsNormalizeTrg
                                  BEFORE INSERT OR UPDATE
                                  ON project_tags
                                  FOR EACH ROW
                                  EXECUTE PROCEDURE normalize_tags();
                                  ")
dbSendQuery(con, project_tagsTriggerQuery)