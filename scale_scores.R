scale_scores <- function(scores, pres=NULL){
  # Using pooled mean and pooled standard deviation
  # if only scores is specified then pres will be
  # washed out by na.rm and not considered
  return((scores - mean(c(scores, pres), na.rm=T))/sd(c(scores, pres), na.rm=T))
}

scale_post_scores <- function(alldf){
  # Get all the post raw score column names
  nms <- colnames(alldf)[str_detect(colnames(alldf),"_post(?!_z)")]
  
  # Set our output column names
  outnms <- paste0(gsub("_raw","",nms),"_z")
  
  # Scale the scores to the appropriate columns by mapping a function onto
  # column names, and utilizing replace functions to find the correspondences
  map(nms, 
      ~ alldf %>% 
        dplyr::select(matches(.x), matches(str_replace(.x, "_post","_pre"))) %>% 
        with(scale_scores(.[[1]],.[[2]]))) %>% 
    set_names(outnms) %>% 
    cbind(alldf,.) %>% 
    as_tibble()
}

scale_pre_scores <- function(alldf){
  # Get all the post raw score column names
  nms <- colnames(alldf)[str_detect(colnames(alldf),"_pre(?!_z)")]
  
  # Set our output column names
  outnms <- paste0(gsub("_raw","",nms),"_z")
  
  # Scale the scores to the appropriate columns by mapping a function onto
  # column names, and utilizing replace functions to find the correspondences
  map(nms, 
      ~ alldf %>% 
        dplyr::select(matches(.x), matches(str_replace(.x, "_pre","_post"))) %>% 
        with(scale_scores(.[[1]],.[[2]]))) %>% 
    set_names(outnms) %>% 
    cbind(alldf,.) %>% 
    as_tibble()
}

scale_all_scores <- function(alldf){
  alldf %>% 
    scale_pre_scores() %>% 
    scale_post_scores() %>% 
    as_tibble()
}



scale_groups <- function(alldf, groupings=NULL){
  # Use groupings from grouped data frame if already grouped
  # otherwise use the grouping specified
  # or just run the easy version if this was called w no groups
  
  if(is.grouped_df(alldf)) {
    grps <- group_split(alldf)
    dots <- groups(alldf)
  } else{
    if(is.null(groupings)) return(scale_all_scores(alldf))
    dots <- lapply(groupings, as.symbol)
    grps <- group_by(alldf, .dots=dots) %>% group_split()
  }
  
  # Get and set column names
  nms <- colnames(alldf)[str_detect(colnames(alldf),"_post(?!_z)")]
  outnms <- paste0(gsub("_raw","",nms),"_z")
  outnms <- c(outnms, gsub("post","pre",outnms)) %>% sort()
  print(outnms)
  
  # Map scale function to all the column names we gathered
  # and do that for each group specified in our list of
  # data frames in grps (hence the nested maps) then 
  # combine everything back together
  
  map(grps,
      ~ map(nms, 
            ~ parent.env(environment())$.x %>% 
              dplyr::select(matches(.x), 
                            matches(str_replace(.x, "post","pre"))) %>%
              with(list(scale_scores(.[[1]],.[[2]]),
                        scale_scores(.[[2]],.[[1]])))) %>% 
        flatten() %>% 
        set_names(outnms) %>% 
        prepend(list('participant' = .x$participant))) %>%
    bind_rows() %>%
    left_join(alldf, ., by='participant') %>%
    group_by(.dots=dots)
}


scale_tst <- tibble(participant = 1:24,
                    hospital = rep(1:3, times=8),
                    group = rep(c("treatment", "control"), times=12),
                    test_A_pre = rnorm(24, 1),
                    test_B_pre = rnorm(24, 50, 25),
                    test_A_post = rnorm(24, 2),
                    test_B_post = rnorm(24, 70, 20))


