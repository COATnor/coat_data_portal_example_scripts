#### ------------------------------------------------------------------------------------------------------------ ####
#### BULK UPLOAD data files to the COAT data portal
#### ------------------------------------------------------------------------------------------------------------ ####

## this script can be used to bulk upload data files to the COAT data portal

## Usually, the readme files will be uploaded first
## then aux and coord file will be uploaded
## then all datafiles will be uploaded in a loop

## the developments version of the ckanr package has to be installed (remotes::install_github("ropensci/ckanr"))

## ---------------------------------- ##
## SETUP ----
## ---------------------------------- ##

## clear workspace
rm(list = ls())

## load libraries, missing packages will be installed
if (!require('remotes')) install.packages('remotes')
if (!require('ckanr')) remotes::install_github("ropensci/ckanr"); library('ckanr')

## setup the connection to the COAT data portal
COAT_url <- "https://coatdemo.coat.no/"  # write here the url to the COAT data portal
COAT_key <- ""  # write here your API key if you are a registered user

# the API can be found on you page on the COAT data portal (log in and click on your name in the upper right corner of the page)
# The use of an API key is necessary to create a package

ckanr_setup(url = COAT_url, key = if (COAT_key == "") NULL else COAT_key)

## specify the name and th version of the dataset you want to upload files to
package_list(as = "table")  # list all available datasets
name <- "test_package_create_v1"  # write correct name including the version of the dataset
version <- "1"    # write here the version of the dataset

## set directories to data files that should be uploaded
dataset_name <- "V_meadow_vascular_plant_abundance_observational"  # write here the dataset names

data.dir <- "C:/Users/hbo042/Box/COAT/Data Management/Formatted data/Tall shrub module/V_meadow_vascular_plant_abundance_observational/Data"  # write here the path to folder with the data files
coord.dir <- "C:/Users/hbo042/Box/COAT/Data Management/Formatted data/Tall shrub module/V_meadow_vascular_plant_abundance_observational"  # write here the path to folder with the coordinate file
aux.dir <- "C:/Users/hbo042/Box/COAT/Data Management/Formatted data/Tall shrub module/V_meadow_vascular_plant_abundance_observational"  # write here the path to folder with the aux file
readme.dir <- "C:/Users/hbo042/Box/COAT/Data Management/Formatted data/Tall shrub module/V_meadow_vascular_plant_abundance_observational/readme" # write here the path to folder with the readme file

## get the package to which resouces should be added
pkg<-package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE, include_drafts = TRUE)$results[[1]]
pkg$resources %>% sapply('[[','url')  # check if datafiles look correct (list() if no data files have been uploaded)
pkg$name  # ckeck name

## get the filenames
filenames <- dir(data.dir) %>%   .[!grepl("coordinates|readme|aux", .)]
coord_name <- paste(dataset_name, "coordinates.txt", sep = "_")
aux_name <- paste(dataset_name, "aux.txt", sep = "_")
readme_name <- paste(dataset_name, "readme.pdf", sep = "_")


## ---------------------------------- ##
## UPLOAD DATA FILES ----
## ---------------------------------- ##


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
filenames <- filenames[!grepl("2019|2020", filenames)]  # select the files that should be uploaded, for example all files up to 2018 for versio 1 of a dataset


for (i in 1:length(filenames)) {
  resource_create(package_id = pkg$id, 
                  name = filenames[i], 
                  upload = paste(data.dir, filenames[i], sep = "/"), 
                  http_method = "POST")
}
                  
  
## ---------------------------------- ##
## END SCRIPT ----
## ---------------------------------- ##

