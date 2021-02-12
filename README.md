# snippets
Collection of small useful functions I've written for different projects so I can use them in future projects.

# R Functions

## `addhalves.cpp`
This file includes a function that's useful for creating matrices where the combination of `(i,j)` or `(j,i)` doesn't matter. Used in a replication of Kawahara (2007) to find counts of consonant pairs in rhyming syllables where the ordering of consonants didn't matter

## `scale_scores.R`
This file includes functions to work with clinical data, specifically pre- and post-treatment test scores. As a result, it can of course also be used for any experiment including pre- and post- evaluations. The functions are used to scale post-values relative to the distribution of the baseline evaluations, so that you can see treatment outcome results. The benefit of these functions is that you don't have to do something like `mutate(test_a_post_z = (test_a_post_raw - mean(test_a_pre_raw))/sd(test_a_pre_raw))` manually for every pair of tests you have. You might think to do something like `mutate(across(contains("pre"), ~scale, .names="{col}_z"))` but this won't let you access the distribution of the pre-scores. You *could* do some wrangling with pivoting, grouping, mutating, regrouping, and repivoting, but this seems like a lot of logical hoops to go through when really all you want is "z-score this using the mean and sd of a corresponding column." I do this by mapping a scaling function to a vector of column names, which lets me modify the strings to access the pre-scores easily. 

Thanks to [akrun's answer on SO](https://stackoverflow.com/questions/49816669/how-to-use-map-from-purrr-with-dplyrmutate-to-create-multiple-new-columns-base) and [James Owers' answer on SO](https://stackoverflow.com/questions/21208801/group-by-multiple-columns-in-dplyr-using-string-vector-input) for some tricks with the data.
