%Run Sparse NMF on behavioral MA similarity matrix with cross-validation

%run_holdout_nested_nmf: nested cross-validation to select best combination of sparsity & number of dimensions
%run_subsets_nmf: subsamples n stimuli x k iterations and runs k-fold CV on each subset to select best num dimensions and sparsity for each subset

% wrappers:  run_holdout_nested_nmf: holds out ~10% of data and runs several iterations of nested cross-validation on training data
%     
%   - for subsampling analyses:
%
%            run_subsets_nmf: subsamples m stimuli (x n iterations) and runs k-fold CV on each subset to select best num dimensions for each subset
%            run_subsets_categ_nmf: removes m action categories (x n iterations) and runs k-fold CV on each subset to select best num dimensions for each subset
%            run_subsets_selective_nmf: selectively removes certain stimulus categories and reruns NMF procedure (to check how well components generalize across categories)
%
% functions: run_kfold_nested_nmf: holds out a third of data for selecting the number of dimensions, and runs k-fold CV on the rest of the data for sparsity selection
%            run_kfold_nmf: performs cross-validation (separately for each pair of stimuli)
%            run_ndim_nmf: loops through different numbers of dimensions to run NMF
%            run_nmf: runs NMF on selected fold looping through specified sparsity parameters for W and H
%
%            sim_impute: impute NaN values in a similarity matrix (useful in Exp 1, where a small number of values may be missing)
%            copy_nmf_stimuli: copy video stimuli to a new folder after thresholding based on NMF weights, for use in further experiments
%
% plotting:  plot_cv_nmf: plot cross-validation performance
%            plot_comp_nmf: plot the video frames corresponding to highest/lowest W weights for each dimension
%            plot_subsets_nmf: plot the optimal number of dimensions against stimulus subset size
%
% DC Dima 2021 (diana.c.dima@gmail.com)

%% set paths

clear; close all; clc
basepath = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_nmf';
addpath(genpath(fullfile(basepath,'analysis')));

% select dataset number
dataset = 1; 

% libraries & dependencies
addpath(genpath(fullfile(basepath,'Scripts/meg-mvpa/mvpa-for-meg/'))); mvpa_setup %for plotting

% results path
savepath = fullfile(basepath,'results','nmf',sprintf('exp%d',dataset));

% paths to behavioral RDM files
datapath = fullfile(basepath,'data',sprintf('exp%d',dataset));

% set seed
rng(10)

% general NMF settings
options = [];
options.verbose = 1;
options.max_epoch = 100;
options.lambda = 1;
options.cost = 'EUC';

% cross-validation options: 5 x 2foldCV
cfg = [];
cfg.kfold = 2;
cfg.kiter = 5;
cfg.options = options;
cfg.metric = 'kendall';  

% sparsity range
cfg.sparsityW = 0:0.1:0.8;
cfg.sparsityH = 0:0.1:0.8;

%% Load data

rdmpath = fullfile(datapath, 'rdm.mat');
load(rdmpath,'rdm','stimlist','framearray')

%convert (normalized) RDM to similarity matrix
rdm = 1-rdm; 

%dataset-specific options
if dataset==1
    cfg.cvscheme = 'pairwise';
    cfg.dimrange = [2:50 60:10:150];
else
    cfg.cvscheme = 'subjectwise';
    cfg.dimrange = 2:65;
end

%% run NMF with nested cross-validation

results = run_holdout_nested_nmf(rdm, cfg);
savefile = 'nmf_results.mat';
save(fullfile(savepath,savefile),'-v7.3', 'results','cfg')

%% plot results

%components
dim = plot_comp_nmf(results,framearray,savepath,stimlist,'top8');
save(fullfile(savepath,savefile),'-append','dim');

%cross-validation performance
plot_cv_nmf(results,cfg)

%% control analysis: selectively remove videos

vidfeatfile = fullfile(datapath,'video_features.mat');
load(vidfeatfile,'env')

cfg.envidx = env;
cfg.stimlist = stimlist;
cfg.kiter = 5;
cfg.sparsityW = [0.1 0.2];
cfg.sparsityH = [0.1 0.2];

if dataset==1
    cfg.dimrange = [2:1:30 40:10:120];
else
    cfg.dimrange = 2:65;
end

results = run_subsets_selective_nmf(rdm, cfg);
savefile = 'nmf_subsets_selective_holdout.mat';
save(fullfile(basepath,savefile),'-v7.3', 'results','cfg')

%% dimensionality analyses for Experiment 1

%%%% dimensionality vs number of stimuli

cfg.kiter = 1;
cfg.szrange = 30:20:140; %subset sizes to sample
cfg.szreps = 10;         %number of iterations
cfg.sparsityW = 0.1;
cfg.sparsityH = 0.1;
cfg.dimrange = [2:1:30 40:10:120];

results = run_subsets_nmf(rdm, cfg);
savefile1 = 'nmf_subsets.mat';
save(fullfile(savepath,savefile1), 'results','cfg')

%%%% dimensionality vs number of action categories
 
cfg.kiter = 1;
cfg.szrange = 1:18;      %number of categories to leave out
cfg.szreps = 10;         %number of iterations
cfg.sparsityW = 0.1;
cfg.sparsityH = 0.1;
cfg.dimrange = [2:1:50 40:10:150];

results = run_subsets_categ_nmf(rdm, cfg);
savefile2 = 'nmf_subsets_categories.mat';
save(fullfile(savepath,savefile2), 'results','cfg')

%%%% plot results
load(fullfile(savepath,savefile1))
figure; subplot(1,2,1)
plot_subsets_nmf(results,cfg)
load(fullfile(savepath,savefile2))
subplot(1,2,2)
plot_subsets_nmf(results,cfg)
xlabel('Categories removed')


