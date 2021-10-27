# mot_nmf
Run cross-validated sparse non-negative matrix factorization to investigate the underlying dimensions in a behavioral similarity matrix.

__Main analysis:__ `nmfscript.m`

__subsampling analyses:__

* `run_subsets_nmf`: draw random samples from the dataset to check how dimensionality changes with dataset sizse
* `run_subsets_categ_nmf`: remove action categories from the dataset to check how dimensionality changes with the number of actions in the dataset
* `run_subsets_selective_nmf`: selectively removes certain stimulus categories to check how well NMF components generalize 

__functions:__

* `run_holdout_nested_nmf`: holds out ~10% of data; runs several iterations of nested cross-validation on training data to find k (num components) and s (sparsity); retrains on whole training set to get number of components
* `run_kfold_nested_nmf`: runs outer cross-validation to select best k
* `run_kfold_nmf`: runs inner cross-validation to select best s
* `run_ndim_nmf`: loops through different k (numbers of dimensions) to run NMF
* `run_nmf`: loops through different s (sparsity parameters) to run NMF using specified k

__plotting:__  

* `plot_cv_nmf`: plot cross-validation performance
* `plot_comp_nmf`: plot frames from the highest/lowest weighted videos corresponding to each component
* `plot_subsets_nmf`: plot the optimal number of dimensions against stimulus subset size
