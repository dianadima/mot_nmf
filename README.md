# mot_nmf
Code for running NMF on the Moments in Time RDM based on multiple arrangement of videos.

Main analysis: `nmfscript.m`

* `run_holdout_nmf`: holds out 1 observation per stimulus pair for testing, runs internal k-fold CV on training set to select best num dimensions and sparsity
* `run_subsets_nmf`: subsamples n stimuli x k iterations and runs k-fold CV on each subset to select best num dimensions and sparsity for each subset

functions: 

* `run_kfold_nmf`: performs cross-validation (separately for each pair of stimuli)
* `run_ndim_nmf`: loops through different numbers of dimensions to run NMF
* `run_nmf`: runs NMF on selected fold looping through specified sparsity parameters for W and H

plotting:  
* `plot_holdout_nmf`: plot the best correlation achieved on training & test set for the best sparsity parameters against number of dimensions
* `plot_subsets_nmf`: plot the number of dimensions achieving the gradient minimum (training & test correlation) against stimulus subset size
* `plot_comp_nmf`: plot the video frames corresponding to highest/lowest W weights for each dimension
* `plot_parameters_nmf`: for each number of dimensions, plot the training & test correlation obtained with different sparsity parameters for W and H

dependencies: 
* `sim_impute`: impute NaN values in a similarity matrix using ultrametric method
