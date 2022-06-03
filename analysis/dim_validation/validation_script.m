% Analyze behavioral results from NMF validation experiments.

%% set paths

clear; close all; clc
basepath = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_nmf';
addpath(genpath(fullfile(basepath,'analysis')));
addpath('/Users/dianadima/OneDrive - Johns Hopkins/Desktop/Scripts/transformer-models/')

% results path
savepath = fullfile(basepath,'results','validation');

% paths to behavioral RDM files
datapath = fullfile(basepath,'data','validation');

% path to NMF results
nmfpath = '/Users/dianadima/OneDrive - Johns Hopkins/Desktop/MomentsInTime/mot_nmf/results/nmf';

% set seed
rng(10)

%% read labels, visualize & run sentiment analysis

val_readdata(datapath,savepath)
val_wordclouds(savepath)
val_sentimentanalysis(savepath)

%% get distances between FastText embeddings and plot results

val_fasttextfeat(savepath)
val_plotresults(savepath)
val_plotspider(savepath)

%% dimension mapping across experiments
val_dimensionmapping(nmfpath,savepath)