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
} else if (!dbExistsTable(con, "projects")){
  dbSendQuery(con, projectsCreateTableQuery)
}

#only run if the parsing of language info is enabled
#TODO: category can have only 3 values, is there s.th. like factor in R for pgSQL?
languagesCreateTableQuery <- paste("CREATE TABLE languages (id integer primary key, name varchar(40), nice_name text, category varchar(40), code bigint, comments bigint, blanks integer, comment_ratio float, projects integer, contributors integer, commits integer);")
if(dbExistsTable(con, "languages") && testRun && parseLang) {
  dbSendQuery(con, "DROP TABLE languages;")
  dbSendQuery(con, languagesCreateTableQuery)
} else if (!dbExistsTable(con, "languages") && parseLang){
  dbSendQuery(con, languagesCreateTableQuery)
}

tagsCreateTableQuery <- paste("CREATE TABLE tags (id serial primary key, tag text UNIQUE);")
if(dbExistsTable(con, "tags") && testRun) {
  dbSendQuery(con, "DROP TABLE tags CASCADE;")
  dbSendQuery(con, tagsCreateTableQuery)
} else if (!dbExistsTable(con, "tags")){
  dbSendQuery(con, tagsCreateTableQuery)
}

project_tagsCreateTableQuery <- paste("CREATE TABLE project_tags (project_id integer references projects (id), tag_id integer references tags (id), id serial primary key);")
if(dbExistsTable(con, "project_tags") && testRun) {
  dbSendQuery(con, "DROP TABLE project_tags;")
  dbSendQuery(con, project_tagsCreateTableQuery)
} else if (!dbExistsTable(con, "project_tags")){
  dbSendQuery(con, project_tagsCreateTableQuery)
}

#when ohloh updates projects, new analysis are created. In order to allow to store multiple analysis for one project, the project id is used as foreign key
analysisCreateTableQuery <- paste("CREATE TABLE analysis (id integer primary key, url text, project_id integer references projects (id), updated_at date, logged_at date, min_month date, max_month date, twelve_month_contributor_count integer, total_code_lines integer, main_language_id integer references languages (id));")
if(dbExistsTable(con, "analysis") && testRun) {
  dbSendQuery(con, "DROP TABLE analysis CASCADE;")
  dbSendQuery(con, analysisCreateTableQuery)
} else if(!dbExistsTable(con, "analysis")) {
  dbSendQuery(con, analysisCreateTableQuery)
}

#activity facts are parsed by analysis_id
activity_factsCreateTableQuery <- paste("CREATE TABLE activity_facts (month date, code_added integer, code_removed integer, comments_added integer, comments_removed integer, blanks_added integer, blanks_removed integer, commits integer, contributors integer, analysis_id integer references analysis(id), id integer primary key);")
if(dbExistsTable(con, "activity_facts") && testRun) {
  dbSendQuery(con, "DROP TABLE activity_facts CASCADE;")
  dbSendQuery(con, activity_factsCreateTableQuery)
} else if(!dbExistsTable(con, "activity_facts")) {
  dbSendQuery(con, activity_factsCreateTableQuery)
}

licensesCreateTableQuery <- paste("CREATE TABLE licenses (name varchar(40) UNIQUE, nice_name text, id serial primary key);")
if(dbExistsTable(con, "licenses") && testRun) {
  dbSendQuery(con, "DROP TABLE licenses CASCADE;")
  dbSendQuery(con, licensesCreateTableQuery)
} else if (!dbExistsTable(con, "licenses")){
  dbSendQuery(con, licensesCreateTableQuery)
}

project_licensesCreateTableQuery <- paste("CREATE TABLE project_licenses (id serial primary key, project_id integer references projects (id), license_id integer references licenses (id) );")
if(dbExistsTable(con, "project_licenses") && testRun) {
  dbSendQuery(con, "DROP TABLE project_licenses;")
  dbSendQuery(con, project_licensesCreateTableQuery)
} else if (!dbExistsTable(con, "project_licenses")){
  dbSendQuery(con, project_licensesCreateTableQuery)
}

#create a function to automatically normalize the tags into a table tags and project_tags
project_normalize_tagsFunctionQuery <- paste("CREATE OR REPLACE FUNCTION normalize_tags(new_project_id INTEGER, new_tag TEXT) RETURNS BOOLEAN AS $BODY$
DECLARE
temp_tag int := 0;
BEGIN
temp_tag := (SELECT id FROM tags WHERE tag = new_tag);
IF temp_tag != 0 THEN
INSERT INTO project_tags (project_id, tag_id) VALUES (new_project_id, temp_tag);
RETURN TRUE;
END IF;
INSERT INTO tags (tag) VALUES (new_tag);
temp_tag := (SELECT id FROM tags WHERE tag =  new_tag);
INSERT INTO project_tags (project_id, tag_id) VALUES (new_project_id, temp_tag);
RETURN TRUE;
END;
$BODY$ LANGUAGE plpgsql;
")
dbSendQuery(con, project_normalize_tagsFunctionQuery)

#create a function to automatically normalize the licenses into a table licenses and project_licenses
project_normalize_licensesFunctionQuery <- paste("CREATE OR REPLACE FUNCTION normalize_licenses(new_project_id INTEGER, new_name TEXT, new_nice_name TEXT) RETURNS BOOLEAN AS $BODY$
DECLARE
tempLicenseId int := 0;
BEGIN
tempLicenseId := (SELECT id FROM licenses WHERE name = new_name);
IF tempLicenseId != 0 THEN
INSERT INTO project_licenses (project_id, license_id) VALUES (new_project_id, tempLicenseId);
RETURN TRUE;
END IF;
INSERT INTO licenses (name, nice_name) VALUES (new_name, new_nice_name);
tempLicenseId := (SELECT id FROM licenses WHERE name =  new_name);
INSERT INTO project_licenses (project_id, license_id) VALUES (new_project_id, tempLicenseId);
RETURN TRUE;
END;
$BODY$ LANGUAGE plpgsql;")
dbSendQuery(con, project_normalize_licensesFunctionQuery)