# snippets
Collection of small useful functions I've written for different projects so I can use them in future projects.

# R Functions

## `addhalves.cpp`
This file includes a function that's useful for creating matrices where the combination of `(i,j)` or `(j,i)` doesn't matter. Used in a replication of Kawahara (2007) to find counts of consonant pairs in rhyming syllables where the ordering of consonants didn't matter

### `add_halves(mat, upper=true)`
  - **Args**: `mat`, a matrix with equal columns and rows; `upper`, should the sums be put in the upper triangle half or the lower? Defaults to upper.
  - **Out**: A matrix with the same dimensions as `mat` with the sums of `mat[i][j] + mat[j][i]` placed in the upper or lower triangle. The other half is replaced with 0s. C++ datatype is `Rcpp::NumericMatrix`.
  - **Dependencies**: `Rcpp` (for compilation)
  - **Notes**: The input matrix can be obtained by doing something like `table(v1,v2) %>% as.data.frame.array() %>% as.matrix()` (where `v1` and `v2` are vectors with equal length). There's probably a prettier way to force the cross tabulation into a matrix form, but this works well enough, and you can write a wrapper function for it if you want. Also, I would recommend casting the input vectors to be **factors** and making sure that they have the same levels, it helps with making sure the matrix has the same dimensions (so you don't have size `n` for the cols and size `n-1` for the rows because one value just didn't appear in the second vector). Lastly, the language is C++, so make sure to use `Rcpp::sourceCpp()`.

## `scale_scores.R`
This file includes functions to work with clinical data, specifically pre- and post-treatment test scores. As a result, it can of course also be used for any experiment including pre- and post- evaluations. The functions are used to scale post-values relative to the distribution of the baseline evaluations, so that you can see treatment outcome results. The benefit of these functions is that you don't have to do something like `mutate(test_a_post_z = (test_a_post_raw - mean(test_a_pre_raw))/sd(test_a_pre_raw))` manually for every pair of tests you have. You might think to do something like `mutate(across(contains("pre"), ~scale, .names="{col}_z"))` but this won't let you access the distribution of the pre-scores. You *could* do some wrangling with pivoting, grouping, mutating, regrouping, and repivoting, but this seems like a lot of logical hoops to go through when really all you want is "z-score this using the mean and sd of a corresponding column." I do this by mapping a scaling function to a vector of column names, which lets me modify the strings to access the pre-scores easily. Thanks to [akrun's answer on SO](https://stackoverflow.com/questions/49816669/how-to-use-map-from-purrr-with-dplyrmutate-to-create-multiple-new-columns-base) which served as a reference.
### `scale_scores(scores, pres=NULL)`
  - **Args**: `scores`, a numeric vector of raw values; `pres`, a numeric vector, optional.
  - **Out**: z-scores of `scores` using the distribution of `pres` if `pres` is specified. If `pres` is not specified, the distribution of `scores` will be used instead.
  - **Dependencies**: `tidyverse`
  - **Notes**: Will **not** throw an error if there are missing values, `na.rm=TRUE` is used. `pres` doesn't *have* to be the same length as `scores`.

### `scale_post_scores(alldf)`
  - **Args**: `alldf`, a dataframe with your scores, can have other columns
  - **Out**: the same dataframe but with new columns for the post z-scores (given by `{col}_z`)
  - **Dependencies**: `tidyverse`
  - **Notes**: This assumes that your columns are named like `Test_post` or `Test_post_raw` and `Test_pre` or `Test_pre_raw` ***respectively***. Each pair of pre and post test columns needs to be formatted the same way, since the matching works by changing "post" to "pre". Similarly, you *must* have a pre-test column for every post-test column. Also, I have `_raw` set to be removed, so for example `Test_A_post_raw` and `Test_A_pre_raw` will be used to generate a column `Test_A_post_z`.
  
### `scale_pre_scores(alldf)`
  - **Args**: `alldf`, a dataframe with your scores, can have other columns
  - **Out**: the same dataframe but with new columns for the pre z-scores (given by `{col}_z`)
  - **Dependencies**: `tidyverse`
  - **Notes**: This doesn't require post-tests to exist, as it doesn't reference them.

### `scale_all_scores(alldf)`
  - **Args**: `alldf`, a dataframe with your scores, can have other columns
  - **Out**: the same dataframe but with new columns for the pre z-scores (given by `{col}_z`)
  - **Dependencies**: `tidyverse`
  - **Notes**: This is just a wrapper for `mydata %>% scale_pre_scores() %>% scale_post_scores()`
    
### `scale_groups(alldf, groupings=NULL)`
  - **Args**: `alldf`, a dataframe with your scores, can have other columns. `groupings`, vector of strings of the column names you want to group by. Might change it to `...` in the future. `alldf` can be a grouped data frame, in which case nothing should be passed to `groupings`, and if you provide any further groupings they will be ignored.
  - **Out**: the same dataframe but with new columns for the pre z-scores (given by `{col}_z`) *but grouped by groupings*
  - **Dependencies**: `tidyverse`
  - **Notes**: Instead of using all of the observations when calculating scores, it will calculate scores based on groups. Eg if you have 20 patients, 10 control and 10 treatment, this will calculate the pre- and post- scores for the control group and treatment group separately, but both scores will be held in the same column. There's an example tibble at the end of the file you can use to look at the behavior. Note that `scale_groups(alldf)` will be equivalent to `scale_all_scores(alldf)` if `alldf` is not a grouped dataframe. Lastly, this function assumes that participants/patients/subjects are held in a column called `participant`; will likely make this more general in the future.
