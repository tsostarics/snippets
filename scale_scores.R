scale_scores <- function(scores, pres=NULL){
  if(is.null(pres)) pres <- scores
  return((scores - mean(pres, na.rm=T))/sd(pres, na.rm=T))
}

scale_post_scores <- function(alldf){
  nms <- colnames(alldf)[str_detect(colnames(alldf),"_post(?!_z)")]
  outnms <- paste0(gsub("_raw","",nms),"_z")
  map(nms, 
      ~ alldf %>% 
        dplyr::select(matches(.x), matches(str_replace(.x, "_post","_pre"))) %>% 
        with(scale_scores(.[[1]],.[[2]]))) %>% 
    set_names(outnms) %>% 
    cbind(alldf,.) %>% 
    as_tibble()
}

scale_pre_scores <- function(alldf){
  out <- mutate(alldf, across(contains("_pre"), scale_scores, .names="{col}_z"))
  colnames(out) <- str_replace(colnames(out), "_raw_z", "_z")
  return(as_tibble(out))
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
  # Get column names
  nms <- colnames(alldf)[str_detect(colnames(alldf),"_post(?!_z)")]
  outnms <- paste0(gsub("_raw","",nms),"_z")
  map(grps,
      ~ map(nms, 
            ~ parent.env(environment())$.x %>% 
              dplyr::select(matches(.x), 
                            matches(str_replace(.x, "post","pre"))) %>% 
                   with(scale_scores(.[[1]],.[[2]]))) %>%
        set_names(outnms) %>% 
        prepend(list('participant' = .x$participant))) %>% 
    bind_rows() %>% 
    left_join(alldf, ., by='participant') %>% 
    group_by(.dots=dots)
}

# tst <- tibble(participant = 1:24,
#               hospital = rep(1:3, times=8),
#               group = rep(c("treatment", "control"), times=12),
#               test_A_pre = rnorm(24, 1),
#               test_B_pre = rnorm(24, 50, 25),
#               test_A_post = rnorm(24, 2),
#               test_B_post = rnorm(24, 70, 20))