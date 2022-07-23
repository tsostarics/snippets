library(slackr)     # Slack API
library(dplyr)      # Wrangling
library(purrr)      # Wrangling
library(lubridate)  # Datetime conversion
library(httr)       # For API call contents


# Save bot token here from https://api.slack.com/apps/
# Make sure it has the correct scopes and that it's been added to each channel
# To add: Channel>Dropdown Menu>Integrations>Add App
tkn <- "" # Should start with xoxb


# Run setup, shouldn't need to worry about the webhook since we're not posting
# any messages. Channel option defaults to general.
slackr::slackr_setup(token = tkn)

# For getting number of pages
initial_call <- slackr:::call_slack_api('/api/files.list',
                                        .method = "GET",
                                        token = tkn,
                                        oldest = 0,
                                        inclusive = "true",
                                        show_files_hidden_by_limit = "true")

num_pages <- content(initial_call)$paging$pages

# Get all the files from each page
pages <- lapply(seq_len(num_pages),
                \(i)
                slackr:::call_slack_api('/api/files.list',
                                        .method = "GET",
                                        token = tkn,
                                        oldest = 0,
                                        inclusive = "true",
                                        show_files_hidden_by_limit = "true",
                                        page= i))

# Get list of contents
contents <- lapply(pages, \(x) content(x)$files)

# Extract relevant file info from contents
extracted_files <- 
  purrr::map_dfr(contents, 
                 \(x) 
                 map_dfr(x, 
                         \(y) {
                           data.frame(timestamp = 
                                        strsplit(
                                          as.character(
                                            lubridate::as_datetime(
                                              y$timestamp)),
                                          " ")[[1L]][1L],
                                      filename = y$name,
                                      url_private = y$url_private,
                                      id = first(y$channels))
                         }
                 )
  )

# Get channel names to merge in
channel_info <- 
  slackr::slackr_channels() |> 
  dplyr::select(id, name, name_normalized)

# Final dataframe with file info
all_file_info <- dplyr::left_join(extracted_files, channel_info, by = 'id')


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
#' @param file_df Dataframe of file information
#' @param directory Directory to save to (within current directory)
#' @param subdirectory Subdirectory to save files to, recommended a subdirectory
#' per channel
#' @param limit_rate Time to wait between downloading files, in seconds. Default
#' 10 but randomness is added (N[3,1])
#' @param test Logical, default FALSE. If TRUE, will only download the first
#' 10 files in each channel. Useful to make sure things are working.
#'
#' @return Invisibly returns 0
save_files <- function(file_df,
                       directory = 'slackfiles/', 
                       subdirectory = '',
                       limit_rate = 10L,
                       test = FALSE) {
  save_dir <- paste0(directory, subdirectory, "/")
  
  # If the directory doesn't exist we need to make it
  if (!dir.exists(save_dir))
    dir.create(save_dir)
  
  # Limit to first 10 files if just testing things
  if (test) 
    file_df <- head(file_df)
  
  for (file_i in seq_len(nrow(all_file_info))) {
    cur_file <- all_file_info[file_i,]
    
    # Make the directory for the file
    file_dir <- paste0(save_dir, cur_file$timestamp, "_", cur_file$filename)
    
    if (file.exists(file_dir))
      next
    
    # Download file to the file directory then pause
    download.file(url = cur_file$url_private, destfile = file_dir)
    Sys.sleep(round(rnorm(1L, 3L, 1L), 2L) + limit_rate)
  }
  invisible(0)
}


# Download all files
all_file_info |> 
  split(~name) |> 
  purrr::walk(.f = \(x) save_files(x,
                                   directory = "prosdlab/slackfiles/",
                                   subdirectory = first(x[['name_normalized']]),
                                   limit_rate = 10L,
                                   test = FALSE))
