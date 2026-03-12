#### ------------------------------------------------------------------------------------------------------------ ####
#### DELETE FILES FROM + UPLOAD FILES TO A DATASET VERSION ON THE COAT DATA PORTAL
#### ------------------------------------------------------------------------------------------------------------ ####

## this script can be used to delete files from a version of a dataset on the COAT data portal, and then upload new files to it

## the development version of the ckanr package has to be installed (remotes::install_github("ropensci/ckanr"))

## ---------------------------------- ##
## SETUP ----
## ---------------------------------- ##

## clear workspace
rm(list = ls())

## load libraries, missing packages will be installed
if (!require('remotes')) install.packages('remotes')
if (!require('ckanr')) remotes::install_github("ropensci/ckanr"); library('ckanr')

## get functions for downloading data from the COAT Data Portal from GitHub (functions from this script)
source("https://github.com/COATnor/data_management_scripts/blob/master/download_data_from_coat_data_portal.R?raw=TRUE")

## set up the connection to the COAT data portal
COAT_url <- "https://data.coat.no"  # write here the url to the COAT data portal
COAT_key <- ""  # write here your API key if you are a registered user

# the API can be found on you page on the COAT data portal (log in and click on your name in the upper right corner of the page)
# the use of an API key is necessary to create a package

ckanr_setup(url = COAT_url, key = COAT_key)

## ---------------------------------- ##
## FIND DATASET FILES TO DELETE
## ---------------------------------- ##

## specify the name and the version of the dataset that you want to modify
package_list(as = "table")  # list all available datasets (shows only public datasets)
name <- "v_rodents_snaptrapping_trapstatus_regional_v1"  # write correct name including the version of the dataset
version <- 1    # write here the version of the dataset

## get the package that should be modified
pkg<-package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE, include_drafts = TRUE)$results[[1]]
pkg$resources %>% sapply('[[','url')  # check if datafiles look correct (list() if no data files have been uploaded)
pkg$name  # check name

## list the names of all data files of the selected dataset (optional)
filenames_delete <- list_data_files(name)  # write here the name of the dataset (choose from the list above)

# selection of files, either select or leave out specific files based on characters in them
filenames_delete <- filenames_delete[grepl("coordinates|aux|2016|2017|2018|2019|2020", filenames_delete)]  # select the files that should be uploaded, for example all files up to 2018 for versio 1 of a dataset
filenames_delete <- filenames_delete[!grepl("2021", filenames_delete)]  # select the files that should be uploaded, for example all files up to 2018 for versio 1 of a dataset


## check that the files that will be deleted have the correct name, and note the description
for (res in pkg$resources) {
  if (res$name %in% filenames_delete) {
    message(paste("Will delete:", res$name, "\nDescription:", res$description, "\n"))
  }
}

## add these descriptions to corresponding files that will be uploaded, under "UPLOAD DATA FILES ----"


## ---------------------------------- ##
## DELETE DATASET FILES
## ---------------------------------- ##

pkg$name  # check name

for (res in pkg$resources) {
  if (res$name %in% filenames_delete) {
    resource_delete(id = res$id)
    message(paste("Deleted:", res$name))
  }
}


## ---------------------------------- ##
## SPECIFY DATA FILES TO UPLOAD
## ---------------------------------- ##

## set directories to data files that should be uploaded
dataset_name <- "V_rodents_snaptrapping_trapstatus_regional"  # write here the dataset names

data.dir   <- "C:/Users/gusyn2253/Box/COAT/Modules/Small rodent module/data/V_rodents_snaptrapping_regional/New_format/Trapstatus"  # write here the path to folder with the data files
coord.dir  <- "C:/Users/gusyn2253/Box/COAT/Modules/Small rodent module/data/V_rodents_snaptrapping_regional/New_format/Trapstatus"  # write here the path to folder with the coordinate file
aux.dir    <- "C:/Users/gusyn2253/Box/COAT/Modules/Small rodent module/data/V_rodents_snaptrapping_regional/New_format/Trapstatus"  # write here the path to folder with the aux file
readme.dir <- "C:/Users/gusyn2253/Downloads" # write here the path to folder with the readme file

## get the package to which resources should be added
pkg<-package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE, include_drafts = TRUE)$results[[1]]
pkg$resources %>% sapply('[[','url')  # check if datafiles look correct (list() if no data files have been uploaded)
pkg$name  # check name

## get the filenames
filenames_upload <- dir(data.dir) %>%   .[!grepl("coordinates|readme|aux", .)]
filenames_upload
coord_name <- paste(dataset_name, "coordinates.txt", sep = "_")
coord_name
aux_name <- paste(dataset_name, "aux.txt", sep = "_")
aux_name
readme_name <- paste(dataset_name, "readme.pdf", sep = "_")
readme_name


## ---------------------------------- ##
## UPLOAD DATA FILES ----
## ---------------------------------- ##

## add the descriptions that were used for the different files before they were deleted, found under the "FIND DATASET FILES TO DELETE" section

## upload readme file
resource_create(package_id = pkg$id, 
                description = "Additional information about the dataset, including a description of the variables included in the dataset.", 
                name = readme_name, 
                upload  = paste(readme.dir, readme_name, sep = "/"), 
                http_method = "POST")

## upload aux file
resource_create(package_id = pkg$id, 
                description = "Auxiliary information about the sampling sites including information about when the site has been included in the sampling design.", 
                name = aux_name, 
                upload  = paste(aux.dir, aux_name, sep = "/"), 
                http_method = "POST")

## upload coordinate file
resource_create(package_id = pkg$id, 
                description = "Coordinates of all sites included in the dataset.", 
                name = coord_name, 
                upload  = paste(coord.dir, coord_name, sep = "/"), 
                http_method = "POST")


## bulk upload of all datafiles
filenames_upload <- filenames_upload[!grepl("2020", filenames_upload)]  # select the files that should be uploaded, for example all files up to 2018 for versio 1 of a dataset
filenames_upload <- filenames_upload[grepl("2016|2017|2018", filenames_upload)]  # select the files that should be uploaded, for example all files up to 2018 for versio 1 of a dataset

## check that the files that will be uploaded have the correct name
for (i in 1:length(filenames_upload)) {
  message(paste("Will upload:", filenames_upload[i]))
}

## upload
for (i in 1:length(filenames_upload)) {
  resource_create(package_id = pkg$id, 
                  name = filenames_upload[i], 
                  upload = paste(data.dir, filenames_upload[i], sep = "/"), 
                  http_method = "POST")
}


## ---------------------------------- ##
## END SCRIPT ----
## ---------------------------------- ##
