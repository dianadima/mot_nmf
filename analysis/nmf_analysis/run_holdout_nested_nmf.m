function [res] = run_holdout_nested_nmf(rdm,cfg)
% run nested cross-validation of sparse NMF on a similarity matrix
% choose parameters based on several CV iterations & retrain with chosen parameters to get final components
%
% cfg
%    cvscheme: cross-validation scheme: 'pairwise': hold out one rating per pair (10% on average)
%                                       'subjectwise': hold out 10% of participants
%    metric: reconstruction accuracy metric: 'kendall', 'pearson', 'rmse', 'frobenius'
%    kiter: number of CV iterations (e.g. 5)
%    kfold: number of folds to use in the inner CV loop (e.g. 2)
%    dimrange: vector with range of k (number of components) to evaluate
%    sparsityW, sparsityH: vectors with range of sparsity for the 2 output matrices to evaluate
%    options: general NMF options (see analysis script/NMF library documentation)
% res
%    output struct (average & holdout results stored in 'avgcv' field)
%
% DC Dima 2021 (diana.c.dima@gmail.com)

%select data to leave out
if strcmp(cfg.cvscheme,'pairwise')
    
    %leave out 1 observation per pair, where there are more than 2 obs
    nvid = size(rdm,2);
    rdmnan = ~isnan(rdm);
    rdmsum = squeeze(sum(rdmnan,1));                    %count how many ratings per pair
    
    rdm_hold = nan(size(rdmsum));
    rdm_train = rdm;
    
    for i = 1:nvid
        rdm_hold(i,i) = 1;                              %manually assign diagonal - assumes similarity matrix
        for j = i+1:nvid                                %symmetric matrix: only use upper triangle
            if rdmsum(i,j)>2
                
                pairvec = rdm(:,i,j);                   %get ratings for each pair
                idx = shuffle(find(~isnan(pairvec)));   %shuffle the ratings 
                holdidx = idx(1);                       %select one to hold out
                
                rdm_hold(i,j) = rdm(holdidx,i,j);       %assign hold-out data to hold-out rdm
                rdm_hold(j,i) = rdm(holdidx,j,i);
                
                rdm_train(holdidx,i,j) = NaN;           %replace with NaN in training RDM
                rdm_train(holdidx,j,i) = NaN;
                
            end
        end
    end
    
elseif strcmp(cfg.cvscheme,'subjectwise')
    
    %subject-wise cross-validation - Exp 2
    holdout_prc = 0.1;
    nsub = size(rdm,1);
    holdout_num = floor(holdout_prc*nsub);
    holdout_idx = randperm(nsub,holdout_num);
    
    rdm_hold = rdm(holdout_idx,:,:);
    rdm_hold = squeeze(nanmean(rdm_hold,1));
    
    rdm_train = rdm;
    rdm_train(holdout_idx,:,:) = [];
    
end


%impute missing values from holdout data 
if any(isnan(rdm_hold(:))), num_holdout_nan = sum(isnan(rdm_hold(:)))/2; fprintf('\nImputing...\n'); rdm_hold = sim_impute(rdm_hold,'ultrametric',1); end

for ik = 1:cfg.kiter

    results = run_kfold_nested_nmf(rdm_train,cfg.dimrange,cfg.kfold,cfg.sparsityW,cfg.sparsityH,cfg.options,cfg.cvscheme,cfg.metric);
    res.kfold{ik} = results;

end

%the avgcv struct contains averaged results from the best sparsity parameter combo for each fold
%typically the same sparsity parameters perform best, so this is not an issue
for i = 1:cfg.kiter
    
    res.avgcv.traincorr(i,:) = squeeze(mean(res.kfold{i}.ndim.traincorr,1));
    res.avgcv.testcorr(i,:) = squeeze(mean(res.kfold{i}.ndim.testcorr,1));
    res.avgcv.truecorr(i) = mean(res.kfold{i}.ndim.truecorr);
    res.avgcv.bestw(i,:) = res.kfold{i}.ndim.bestw;
    res.avgcv.besth(i,:) = res.kfold{i}.ndim.besth;
    
end

%get the elbow point in the average test curve
testcorr = squeeze(mean(res.avgcv.testcorr,1));
[~,eidx] = get_elbowpoint(testcorr,1);

%use it to retrain and get the weight matrices on 90% of data
if ~isempty(eidx)
    
    bestk = cfg.dimrange(eidx);
    bestw = nan(cfg.kiter,1); besth = bestw;
    for k = 1:cfg.kiter
        bestw(k) = res.kfold{i}.ndim.bestw(eidx);
        besth(k) = res.kfold{i}.ndim.besth(eidx);
    end
    
    %get the mode - usually not necessary as parameters identical
    bestw = mode(bestw); bw = find(cfg.sparsityW==bestw);
    besth = mode(besth); bh = find(cfg.sparsityH==besth);

    bestx = res.kfold{1}.kfold_sparsity.x{eidx};
    
    %rerun NMF on whole training set with best options
    options = cfg.options;
    options.x_init.W = bestx.W(:,:,bw,bh);
    options.x_init.H = bestx.H(:,:,bw,bh);
    options.sW = bestw;
    options.sH = besth;
    
    %impute any missing values in training RDM - not necessary as no NaNs here...
    rdm_train_avg = squeeze(nanmean(rdm_train,1));
    if any(isnan(rdm_train_avg(:))), fprintf('\nImputing...\n'); rdm_train_avg = sim_impute(rdm_train_avg,'ultrametric',1); end
    
    %get true correlation
    if strcmp(cfg.metric,'kendall')
        truecorr = rankCorr_Kendall_taua(rdm_hold(:),rdm_train_avg(:));
    elseif strcmp(cfg.metric, 'rmse') %rmse
        truecorr = sqrt(mean((rdm_hold(:) - rdm_train_avg(:)).^2))/(mean(rdm_hold(:)));
    elseif strcmp(cfg.metric,'pearson')
        truecorr = corr(rdm_hold(:),rdm_train_avg(:),'rows','pairwise');
    elseif strcmp(cfg.metric,'frobenius')
        truecorr = norm(rdm_hold(:) - rdm_train_avg(:),'fro')^2 / 2 ;
    end

    %run NMF and get holdout correlation
    [x,~] = nmf_sc(rdm_train_avg,bestk,options);
    mfit = x.W*x.H;
    
    if strcmp(cfg.metric,'kendall')
        holdoutcorr = rankCorr_Kendall_taua(mfit(:), rdm_hold(:));
        traincorr = rankCorr_Kendall_taua(mfit(:), rdm_train_avg(:));
    elseif strcmp(cfg.metric, 'rmse') %rmse
        holdoutcorr = sqrt(mean((rdm_hold(:) - mfit(:)).^2))/(mean(rdm_hold(:)));
        traincorr = sqrt(mean((rdm_train_avg(:) - mfit(:)).^2))/(mean(rdm_train_avg(:)));
    elseif strcmp(cfg.metric,'pearson')
        holdoutcorr = corr(rdm_hold(:),mfit(:),'rows','pairwise');
        traincorr = corr(rdm_train_avg(:),mfit(:),'rows','pairwise');
    elseif strcmp(cfg.metric,'frobenius')
        holdoutcorr = norm(rdm_hold(:) - mfit(:),'fro')^2 / 2 ;
        traincorr = norm(rdm_train_avg(:) - mfit(:),'fro')^2 / 2 ;
    end
    
    %save results
    res.avgcv.holdout.truecorr = truecorr;
    res.avgcv.holdout.holdoutcorr = holdoutcorr;
    res.avgcv.holdout.traincorr = traincorr;
    res.avgcv.holdout.x = x;
    res.avgcv.holdout.numnan = num_holdout_nan;
    res.avgcv.bestk = bestk;
    res.avgcv.bestw = bestw;
    res.avgcv.besth = besth;
    res.avgcv.cfg = cfg;
end


end