library(slackr)     # Slack API
library(dplyr)      # Wrangling
library(purrr)      # Wrangling
library(lubridate)  # Datetime conversion

# Save bot token here from https://api.slack.com/apps/
# Make sure it has the correct scopes and that it's been added to each channel
# To add: Channel>Dropdown Menu>Integrations>Add App
tkn <- "" # Should start with xoxb

# Run setup, shouldn't need to worry about the webhook since we're not posting
# any messages. Channel option defaults to general.
slackr::slackr_setup(token = tkn)

# Get all the public channels in the slack workspace
# Note: If you get a scope error, it should say which scopes need to be added.
#       Do so on the slack app page, then reinstall to workspace and try again.
channel_info <- 
  slackr::slackr_channels() |> 
  # Only keep relevant info
  dplyr::select(id, name, name_normalized, created) |>
  # Add # for API calls
  dplyr::mutate(name = paste0("#", name)) |>
  dplyr::group_by(name) |>
  # Get a dataframe of all the files
  dplyr::mutate(files = 
                  list(
                      slackr:::slackr_history(channel = name,
                                              token = tkn,
                                              posted_from_time = created, 
                                              paginate = FALSE,
                                              message_count = 1000L) # Should be big enough, change if needed
                  ),
                # Filter so that we only get the rows with files in them
                files = ifelse('attachments' %in% colnames(files[[1]]),
                               list(filter(files[[1]], !is.na(attachments))),
                               files)
  )


#' Save files from slack channels
#'
#' Given a list of file data frames in a channel, download each file one by one.
#' Because this will result in a lot of download requests, the delay between
#' requests `limit_rate` should be set to at least 10 or 15. Randomness is also 
#' added to this delay (Normal dist, mean 3 sd 1).
#' 
#' Note that this will take a while to complete. If you start it again later
#' and it detects that a file already exists, it will skip that file
#'
#' @param directory Directory to save to (within current directory)
#' @param subdirectory Subdirectory to save files to, recommended a subdirectory
#' per channel
#' @param file_dfs The `files` list column in each channel, where each entry
#' is a dataframe containing file information. The download link is the
#' `url_private` field in these.
#' @param limit_rate Time to wait between downloading files, in seconds. Default
#' 10 but randomness is added (N[3,1])
#' @param test Logical, default FALSE. If TRUE, will only download the first
#' 10 files in each channel. Useful to make sure things are working.
#'
#' @return Invisibly returns 0
save_files <- function(directory = 'slackfiles/', 
                       subdirectory = '', 
                       file_dfs,
                       limit_rate = 10L,
                       test = FALSE) {
  save_dir <- paste0(directory, subdirectory, "/")
  
  # If the directory doesn't exist we need to make it
  if (!dir.exists(save_dir))
    dir.create(save_dir)
  
  # Limit to first 10 files if just testing things
  if (test) 
    file_dfs <- head(file_dfs)
  
  for (file_df in file_dfs) {
    
    # If a file was deleted, and it was the only file, url_private will not be 
    # available. If one out of multiple files were downloaded, the column will
    # exist but the value will be NA 
    if (!'url_private' %in% colnames(file_df))
      next
    file_df <- dplyr::filter(file_df, !is.na(url_private))
    
    file_name <- file_df$name
    
    # Convert timestamp to date, necessary to prevent clashes 
    # with different files that happen to have the same name
    file_date <- as.character(lubridate::as_datetime(file_df$timestamp))
    file_date <- gsub("[-]", "_", strsplit(file_date, " ")[[1L]][1L])
    
    # Make the directory for the files
    file_dir <- paste0(save_dir, file_date, "_", file_name)
    
    # The previous lines were all vectorized, but now we have to go through each 
    # file individually so that we can skip files that we've already downloaded
    for (file_i in seq_along(file_dir)) {
      # Skip if the file has already been downloaded
      if (file.exists(file_dir[file_i]))
        next
      
      # Download file to the file directory then pause
      download.file(url = file_df$url_private[file_i], destfile = file_dir[file_i])
      Sys.sleep(round(rnorm(1L, 3L, 1L), 2L) + limit_rate)
    }
    
  }
  invisible(0)
}


# Download all files
channel_info |>
  split(~name) |>
  purrr::walk(.f = \(x) save_files(directory = "prosdlab/slackfiles/",
                                   subdirectory = x[['name_normalized']],
                                   file_dfs = x[['files']][[1L]][['files']],
                                   limit_rate = 15L,
                                   test = FALSE))
