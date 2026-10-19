##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## DOWNLOAD DATA FROM THE COAT DATA PORTAL
## last update 05.08.2025
## script made by Hanna Boehner
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

## DESCRIPTION

## This script includes functions and an example for downloading data files from the COAT Data Portal
## The data can either be imported to the current R session or saved on your computer

## For downloading private datasets, you need to specify an API token.
## CKAN no longer issues API keys. Log in to data.coat.no, click your name in the top
## right corner and create one under "Manage" -> "API tokens".
## The API token is private and should not be shared with others.

## IMPORTANT - ckanr must be the version from 2025-11-13 or later.
## Older versions of ckanr sent only the "X-CKAN-API-Key" header, which CKAN 2.10 and
## later ignore. Such a version silently talks to the portal as an anonymous user and
## every private dataset fails with 403, without any error message. Reinstall (or update)
## even if ckanr is already installed, then run the check in the example below.
remotes::install_github("ropensci/ckanr", upgrade = "always")

## You can first list all COAT modules and then list all datasets of the selected module
## From this list you can select the datasets you want to download, list all files belonging to the dataset and select the files you want to download
## then you can download the selected files
# if you already know the names of the dataset and the files you want to download, you can skip the first steps and only run download_coat_data()


## EXAMPLE

if (FALSE) {  # ignore this (prevents running the example when sourcing the script)
  
  ## load libraries (missing libraries will be installed)
  ## ckanr 0.7.0 on CRAN (2023-03-17) sends only X-CKAN-API-Key, which CKAN 2.10 and later
  ## ignore, so an installed ckanr is usually too old. Reinstall unless this one can
  ## authenticate - "auth_headers" is what sends the Authorization header.
  if (!require("ckanr") || !("auth_headers" %in% ls(asNamespace("ckanr")))) {
    remotes::install_github("ropensci/ckanr", upgrade = "always")
  }
  library("ckanr")
  if (!require("tidyverse")) install.packages("tidyverse"); library("tidyverse")
  
  ## get functions for downloading data from the COAT Data Portal from GitHub (functions from this script)
  source("https://github.com/COATnor/data_management_scripts/blob/master/download_data_from_coat_data_portal.R?raw=TRUE")
  
  ## set up the connection to the COAT Data Portal (this is where you need your API token from data.coat.no)
  COAT_key <- ""  # paste your API token here, or leave "" to only read public datasets
  ckanr::ckanr_setup(url =  "https://data.coat.no", 
                     key = if (COAT_key == "") NULL else COAT_key)
  # the API token is created under "Manage" -> "API tokens" on your user page on data.coat.no
  
  ## Check that authentication actually works. A ckanr older than 2025-11-13 sends only
  ## the ignored "X-CKAN-API-Key" header and every private dataset then fails with 403
  ## without any error message, so check for it explicitly here.
  if (nchar(ckanr::get_default_key()) > 0) {
    stopifnot(
      "Your ckanr does not send an Authorization header - it is too old to authenticate.
       Reinstall it with remotes::install_github('ropensci/ckanr', upgrade = 'always')"
        = "Authorization" %in% names(ckanr:::auth_headers(ckanr::get_default_key()))
    )
    ckanr:::auth_headers(ckanr::get_default_key())  # must show Authorization = "<your token>"
  } else {
    message("No API token set - only public datasets will be listed.")
  }
  
  ## list all modules (optional)
  ckanr::organization_list(as = "table")$name
  
  ## list all datasets of a module (optional)
  list_datasets(module = "climate-module")  # wirte here the module name
  
  ## list the names of all data files of the selected dataset (optional)
  filenames <- list_data_files("v_snowdepth_intensive_v1")  # write here the name of the dataset (choose from the list above)
  
  ## download data
  coat_dat <- download_coat_data(name = "v_snowdepth_intensive_v1", # write here name of the dataset (choose from the list above)
                                 filenames = filenames[!grepl("readme|aux|coordinates", filenames)], # names of the files that should be downloaded, e.g. all data files (without readme, aux and coordinate file)
                                 store = "session", #"session" for importing the data in the current R session, "disk" for saving the data on your computer
                                 out.dir = NA) # if store = "disk", you have to specify the path to a folder where the data should be stored
  
  ## combine all data files of the list in one data frame (works only if all files have the same structure)
  dat <- do.call(rbind, coat_dat)
  
}  # ignore this (prevents running the example when sourcing the script)



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## FUNCTIONS
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


download_coat_data <- function(name = name, 
                               version = version,
                               filenames = filenames,
                               store = "session",
                               out.dir = out.dir) {
  
  ## extract the version from the dataset name
  version <- substr(name, nchar(name), nchar(name))
  
  ## search for the dataset
  pkg <- ckanr::package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE)$results[[1]]
  urls <- pkg$resources %>% sapply("[[", "url") # get the urls to the files included in the dataset
  filenames_dataset <- pkg$resources %>% sapply("[[", "name") # get the filenames
  
  ## check if all files are available
  if (!all(filenames %in% filenames_dataset)){
    print("Error: files not found")
    break
  }
  
  ## order filenames chronologically
  chrono <- order(filenames_dataset)
  filenames_dataset <- filenames_dataset[chrono]
  urls <- urls[chrono]
  
  ## urls of filenames that should be downloaded
  urls2 <- urls[which(filenames_dataset %in% filenames)]
  
  ## check if out.dir exists
  if (store == "disk") {
    if(!dir.exists(out.dir)) {
      print("Error: directory does not exist")
      break
    }
  }
  
  ## download all files 
  mylist <- c() # empty object for the files
  
  for (i in 1:length(filenames)) {
    mylist[[i]] <- ckanr::ckan_fetch(urls2[i],
                                     store = store,
                                     path = paste(out.dir, filenames[i], sep = "/"),
                                     sep = ";",
                                     header = TRUE,
                                     #format = "txt"
    )
  }
  
  
  return(mylist)
}

list_datasets <- function(COAT_key = COAT_key, 
                          module = module,
                          printContents = TRUE) {
  
  ## search for all datasets of a module
  all_pkg <- package_search(q = paste0("organization:", module), rows = 1000, include_private = TRUE, as = "table")$results %>% 
    dplyr::mutate(status = ifelse(private, "private", "public")) %>% 
    dplyr::select(name, version, type, status, temporal_start, temporal_end) %>% 
    dplyr::arrange(name)
  
  if(printContents){
    print(all_pkg)
  }
  
  return(all_pkg) 
}

list_data_files <- function(name,
                            printContents = TRUE) {
  
  ## extract the version from the dataset name
  version <- substr(name, nchar(name), nchar(name))
  
  ## list the names of all data files
  pkg <- package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE, as = "table")$results$resources[[1]]
  filenames_dataset <- pkg$name
  
  if(printContents){
    print(filenames_dataset)
  }
  
  return(filenames_dataset)
}


