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

**Usage**: `with(mydata, table(obs1, obs2)) %>% as.data.frame.array() %>% as.matrix %>% add_halves()` where `obs1` and `obs2` are (preferably) factor vectors of the observations you want to cross tabulate with equivalent levels.

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

**Usage**: For pre and post z scores: `mydata %>% scale_pre_scores() %>% scale_post_scores()` (the ordering doesn't matter). Use `scale_post_scores(mydata)` if you just want post scores, you don't have to use both at the same time.
