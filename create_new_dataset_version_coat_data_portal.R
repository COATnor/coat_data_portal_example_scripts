#### ------------------------------------------------------------------------------------------------------------ ####
#### CREATE A NEW VERSION OF A DATASET ON THE COAT DATA PORTAL
#### ------------------------------------------------------------------------------------------------------------ ####

## this script can be used to create a new version of a dataset on the COAT data portal

## the development version of the ckanr package has to be installed (remotes::install_github("ropensci/ckanr"))

## ---------------------------------- ##
## SETUP ----
## ---------------------------------- ##

## clear workspace
rm(list = ls())

## load libraries, missing packages will be installed
if (!require('remotes')) install.packages('remotes')
if (!require('ckanr')) remotes::install_github("ropensci/ckanr"); library('ckanr')

## setup the connection to the COAT data portal
COAT_url <- "https://data.coat.no"  # write here the url to the COAT data portal
COAT_key <- Sys.getenv("API_coat")  # save you API as an environmental variable
# write here your API key if you are a registered user

# CKAN no longer issues API keys. Create an API token on your user page on the COAT data portal
# (log in, click your name, then "Manage" -> "API tokens") and paste it into COAT_key above.
# An API token is necessary to create a package

ckanr_setup(url = COAT_url, key = COAT_key)

## specify the name and the version of the dataset that you want to modify
package_list(as = "table")  # list all available datasets (shows only public datasets)
name <- "v_air_temperature_meadow_v1"  # write correct name including the version of the dataset
version <- 1    # write here the version of the dataset

## get the package that should be modified
pkg<-package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE, include_drafts = TRUE)$results[[1]]
pkg$resources %>% sapply('[[','url')  # check if datafiles look correct (list() if no data files have been uploaded)
pkg$name  # ckeck name



## ---------------------------------- ##
## MODIFY METADTA OF THE NEW VERSION ----
## ---------------------------------- ##

version_new <- version+1  # new version 
name_new <- sub(version, version_new, name)  # name of the new version
name_new  # check the new name

end_new <- "2022-08-31"  # write here the new end date of the dataset 
embargo_new <- "2024-08-31"  # write here the new embargo end date

# These are the typlical modifications when creating a new version of a dataset before adding data of another year
# other modification can be made if necessary

# modify tags (necessary to avoid a validation error)
new_tags <- c()
for (i in 1:length(pkg$tags)){
  new_tags[[i]] <- list(name = pkg$tags[[i]]$name)
}


## ---------------------------------- ##
## CREATE THE NEW VERSION ----
## ---------------------------------- ##

package_create(name = name_new,
               title = pkg$title,
               private = TRUE,  # this is default
               tags = new_tags,
               author = pkg$author,
               author_email = pkg$author_email,
               license_id = pkg$license_id, 
               notes = pkg$notes, 
               version = as.character(version_new), 
               owner_org = pkg$owner_org, 
               state = "active", 
               type = "dataset",
               extras = list(topic_category = pkg$topic_category, 
                             position = pkg$position,
                             publisher = pkg$publisher,
                             associated_parties = pkg$associated_parties,
                             persons = pkg$persons,
                             temporal_start = pkg$temporal_start,
                             temporal_end = end_new,
                             location = pkg$location,
                             scripts = pkg$scripts,
                             protocol = pkg$protocol,
                             bibliography = pkg$bibliography,
                             funding = pkg$funding#,
                             #embargo = embargo_new
               ))



## ---------------------------------- ##
## ADD THE OLD RESOURCES ----
## ---------------------------------- ##

## the resources (data files) of the old version have to be added to the new version of the dataset

## get the new version of the package
pkg_new<-package_search(q = list(paste("name:", name_new, sep = "")), fq = list(paste("version:", version_new, sep = "")), include_private = TRUE, include_drafts = TRUE)$results[[1]]
pkg_new$resources %>% sapply('[[','url')  # check if datafiles look correct (list() if no data files have been uploaded)
pkg_new$name  # ckeck name

## check the old resources
pkg$resources %>% sapply('[[','url')  # check if datafiles look correct (list() if no data files have been uploaded)


# add all resources
for (i in 1:length(pkg$resources)) {
  resource_create(pkg_new$id,
                  rcurl = pkg$resources[[i]]$url, 
                  name = pkg$resources[[i]]$name, 
                  http_method = "POST", 
                  description = pkg$resources[[i]]$description)
}


## ---------------------------------- ##
## ADD THE NEW RESOURCES ----
## ---------------------------------- ##

## add new files to the new version

in.dir <-  "C:/Users/hbo042/Box/COAT/Modules/Climate and snow/data/temperature loggers meadow/cut logger data to data portal 2019-"  # write here the directory to the file(s)

filenames <- dir(in.dir)
filenames <- grep("2022", filenames, value = TRUE)  # select the file you want to upload, you can alos upload several files togehter

## uploade the file(s)
for (i in 1:length(filenames)) {
  resource_create(package_id = pkg_new$id, 
                  name = filenames[i], 
                  upload = paste(in.dir, filenames[i], sep = "/"), 
                  http_method = "POST")
}


## ---------------------------------- ##
## PUPLISH THE DATASET
## ---------------------------------- ##

## Run this part if you want to publish the dataset (set visibility from private to plublic)

pkg_new$name # check that the name is correct

## save metadata of the package as a list (as = table -> but the object will be a list)
pkg_updated <- package_show(pkg_new$id, as = "table", http_method = "POST")

## do the necessary modifications of the metadata
names(pkg_updated) # show the names of all metadata fields that can be updated
pkg_updated$private <- FALSE # set private = FALSE to publish a dataset

## discard empty metadata fields (they will cause a validation error)
pkg_updated <- discard(pkg_updated, is.null)

## update the package
package_update(pkg_updated, pkg_name$id, http_method = "POST")


