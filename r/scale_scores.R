library(tidyverse)
library(rlang) # := won't load for some reason unless I load rlang separately?

scale_scores <- function(scores, pres=NULL, pool=TRUE){
  # Using pooled mean and pooled standard deviation by default, assumes you're
  # providing pre-values along with your post scores. If pool=T but you don't 
  # pass anything to pres, it will be treated as just scores since the NULL gets
  # washed out by na.rm. So, depending on your parameters you can get:
  # pool=T, pres=NULL   --> z-score scores
  # pool=T, pres=c(...) --> z-score scores with pooled mean & sd
  # pool=F, pres=NULL   --> z-score scores
  # pool=F, pres=c(...) --> z-score scores but relative to pre distribution
  
  if(pool) vals <- c(scores, pres)
  else vals <- ifelse(is.null(pres), scores, pres)
  
  return((scores - mean(vals, na.rm=T))/sd(vals, na.rm=T))
}

scale_post_scores <- function(alldf, post_pat="_post", pre_pat="_pre", 
                              raw_pat="_raw", suffix="_z", pool=TRUE){
  # Get all the post raw score column names
  nms <- colnames(alldf)[stringr::str_detect(colnames(alldf),
                                             paste0(post_pat, 
                                                    "(?!",suffix,")"))]
  
  # Set our output column names
  outnms <- paste0(gsub(raw_pat,"",nms), suffix)
  
  # Scale the scores to the appropriate columns by mapping a function onto
  # column names, and utilizing replace functions to find the correspondences
  purrr::map(nms, 
             ~ alldf %>% 
               dplyr::select(dplyr::matches(.x), 
                             dplyr::matches(str_replace(.x, 
                                                        post_pat,
                                                        pre_pat))) %>% 
               with(scale_scores(.[[1]],.[[2]],pool))) %>% 
    rlang::set_names(outnms) %>% 
    cbind(alldf,.) %>% 
    dplyr::as_tibble()
}

scale_pre_scores <- function(alldf, post_pat="_post", pre_pat="_pre", 
                             raw_pat="_raw", suffix="_z", pool=TRUE){
  # Get all the post raw score column names
  nms <- colnames(alldf)[stringr::str_detect(colnames(alldf),
                                             paste0(pre_pat, "(?!",suffix,")"))]
  
  # Set our output column names
  outnms <- paste0(gsub(raw_pat,"",nms),suffix)
  
  # Scale the scores to the appropriate columns by mapping a function onto
  # column names, and utilizing replace functions to find the correspondences
  purr::map(nms, 
            ~ alldf %>% 
              dplyr::select(dplyr::matches(.x),
                            dplyr::matches(str_replace(.x, 
                                                       pre_pat, 
                                                       post_pat))) %>% 
              with(scale_scores(.[[1]],.[[2]],pool))) %>% 
    rlang::set_names(outnms) %>% 
    cbind(alldf,.) %>% 
    dplyr::as_tibble()
}

scale_all_scores <- function(alldf){
  alldf %>% 
    scale_pre_scores() %>% 
    scale_post_scores() %>% 
    as_tibble()
}

scale_groups <- function(alldf, groupings=NULL, pptcol="participant", 
                         post_pat="_post", pre_pat="_pre", raw_pat="_raw", 
                         suffix="_z", pool=TRUE){
  # Use groupings from grouped data frame if already grouped
  # otherwise use the grouping specified
  # or just run the easy version if this was called w no groups
  
  if(is.grouped_df(alldf)) {
    grps <- dplyr::group_split(alldf)
    dots <- dplyr::groups(alldf)
  } else{
    if(is.null(groupings)) return(scale_all_scores(alldf))
    dots <- lapply(groupings, as.symbol)
    grps <- dplyr::group_by(alldf, .dots=dots) %>% dplyr::group_split()
  }
  
  # Get and set column names
  nms <- colnames(alldf)[stringr::str_detect(colnames(alldf),
                                             paste0(post_pat, 
                                                    "(?!", suffix,")"))]
  outnms <- paste0(gsub(raw_pat,"",nms),suffix)
  outnms <- c(outnms, gsub(post_pat,pre_pat,outnms)) %>% sort()
  print(outnms)
  
  # Map scale function to all the column names we gathered
  # and do that for each group specified in our list of
  # data frames in grps (hence the nested maps) then 
  # combine everything back together
  
  purrr::map(grps,
             ~ purrr::map(nms, 
                          ~ parent.env(environment())$.x %>% 
                            dplyr::select(matches(.x), 
                                          matches(str_replace(.x, 
                                                              post_pat, 
                                                              pre_pat))) %>%
                            with(list(scale_scores(.[[1]],.[[2]],pool),
                                      scale_scores(.[[2]],.[[1]],pool)))) %>% 
               purrr::flatten() %>% 
               rlang::set_names(outnms) %>%
               purrr::prepend(list2(!!pptcol := .x[[pptcol]]))) %>%
    dplyr::bind_rows() %>%
    dplyr::left_join(alldf, ., by=pptcol) %>%
    dplyr::group_by(.dots=dots)
}

# scale_tst <- tibble(participant = 1:24,
#                     hospital = rep(1:3, times=8),
#                     group = rep(c("treatment", "control"), times=12),
#                     test_A_pre = rnorm(24, 1),
#                     test_B_pre = rnorm(24, 50, 25),
#                     test_A_post = rnorm(24, 2),
#                     test_B_post = rnorm(24, 70, 20))

# Typical usage is like so:
# scale_tst %>% group_by(hospital) %>% scale_groups()