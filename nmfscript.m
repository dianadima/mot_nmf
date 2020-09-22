%Run NMF on behavioral MA RDM with cross-validation

%run_holdout_nmf: holds out 1 observation per stimulus pair for testing, runs internal k-fold CV on training set to select best num dimensions and sparsity
%run_subsets_nmf: subsamples n stimuli x k iterations and runs k-fold CV on each subset to select best num dimensions and sparsity for each subset

%functions: run_kfold_nmf: performs cross-validation (separately for each pair of stimuli)
%           run_ndim_nmf: loops through different numbers of dimensions to run NMF
%           run_nmf: runs NMF on selected fold looping through specified sparsity parameters for W and H
%plotting:  plot_holdout_nmf: plot the best correlation achieved on training & test set for the best sparsity parameters against number of dimensions
%           plot_subsets_nmf: plot the number of dimensions achieving the gradient minimum (training & test correlation) against stimulus subset size
%           plot_comp_nmf: plot the video frames corresponding to highest/lowest W weights for each dimension
%           plot_parameters_nmf: for each number of dimensions, plot the training & test correlation obtained with different sparsity parameters for W and H
%
%dependencies: sim_impute: impute NaN values in a similarity matrix using ultrametric method

%% set paths

clear; close all; clc

%libraries
%mvpa toolbox (for plotting functions): https://github.com/dianadima/mvpa-for-meg
addpath(genpath('/Users/diana/Desktop/Scripts/meg-mvpa/mvpa-for-meg/'));mvpa_setup %for plotting

%NMF library: https://github.com/hiroyuki-kasai/NMFLibrary
addpath(genpath('/Users/diana/Desktop/Scripts/NMFLibrary'))                 %nmf_sc version
addpath('/Users/diana/Desktop/Scripts/NMFLibrary/auxiliary/initialization') %for nnsvd

%path to NMF analysis scripts
basepath = fileparts(pwd); %one level up from current
rdmpath = '/Users/diana/Desktop/MomentsInTime/MoT_Behavior/MoT_Similarity/data/analysis/rdm.mat';
load(rdmpath,'rdm')

%set seed
rng(10)

%% for pilot data - load, reshape and normalize pilot RDM
% rdmpath = '/Users/diana/Desktop/MomentsInTime/MoT_Behavior/MoT_SimilarityPilot/Results/alldata.mat';
% load(rdmpath,'rdm');
% rdm1 = rdm; rdm = nan(size(rdm,2),50,50);
% for i = 1:size(rdm1,2)
%     tmp = squareform(squeeze(rdm1(:,i)));
%     tmp = (tmp-min(tmp))./(max(tmp)-min(tmp));
%     rdm(i,:,:) = tmp;
% end

%% general options

options = [];
options.verbose = 1;
options.max_epoch = 100;
options.lambda = 1;
options.cost = 'EUC';

cfg = [];
cfg.kfold = 2;
cfg.options = options;
cfg.sparsityW = [0 0.2:0.1:0.8];
cfg.sparsityH = [0 0.2:0.1:0.8];
cfg.dimrange = [2:1:60 70:10:130];
%cfg.dimrange = 2:1:40; %for pilot data (50 stim)

%% nested CV for optimal k on full set (holdout + k-fold CV)

results = run_holdout_nmf(rdm, cfg);

savefile = 'nmf_holdout.mat';
save(fullfile(basepath,savefile), 'results','cfg')

%% dimensionality vs number of stimuli

cfg.szrange = 30:20:140; %subset sizes to sample
cfg.szreps = 20;         %number of iterations
cfg.sparsityW = 0.2:0.2:0.8;
cfg.sparsityH = 0.2:0.2:0.8;
cfg.dimrange = [2 5 8 10:10:130];

results = run_subsets_nmf(rdm, cfg);

savefile = 'nmf_subsets.mat';
save(fullfile(basepath,savefile), 'results','cfg')