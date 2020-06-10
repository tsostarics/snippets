scale_scores <- function(scores, pres=NULL){
  if(is.null(pres)) pres <- scores
  return((scores - mean(pres, na.rm=T))/sd(pres, na.rm=T))
}

scale_post_scores <- function(alldf){
  nms <- colnames(alldf)[str_detect(colnames(alldf),"post(?!_z)")]
  outnms <- paste0(gsub("_raw","",nms),"_z")
  map(nms, 
      ~ alldf %>% 
        dplyr::select(matches(.x), matches(str_replace(.x, "post","pre"))) %>% 
        with(scale_scores(.[[1]],.[[2]]))) %>% 
    set_names(outnms) %>% 
    cbind(alldf,.)
}

scale_pre_scores <- function(alldf){
  out <- mutate(alldf, across(contains("_pre"), scale_scores, .names="{col}_z"))
  colnames(out) <- str_replace(colnames(out), "_raw_z", "_z")
  return(out)
}