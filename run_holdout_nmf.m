function [results] = run_holdout_nmf(rdm,cfg)

%select data to leave out
%leave out 1 observation per pair, where there are more than 2 obs
nvid = size(rdm,2);
rdmnan = ~isnan(rdm);
rdmsum = squeeze(sum(rdmnan,1));
rdm_hold = nan(size(rdmsum));
rdm_train = rdm;
for i = 1:nvid
    rdm_hold(i,i) = 0;
    for j = i+1:nvid
        if rdmsum(i,j)>2
            
            pairvec = rdm(:,i,j);
            idx = shuffle(find(~isnan(pairvec)));
            holdidx = idx(1);
            
            rdm_hold(i,j) = rdm(holdidx,i,j);
            rdm_hold(j,i) = rdm(holdidx,j,i);
            
            rdm_train(holdidx,i,j) = NaN;
            rdm_train(holdidx,j,i) = NaN;
        
        end
    end
end

%impute missing values from holdout data 
if any(isnan(rdm_hold(:))), rdm_hold = sim_impute(rdm_hold,'ultrametric'); end

%run kfold CV on training data
results = run_kfold_nmf(rdm_train,cfg.dimrange,cfg.kfold,cfg.sparsityW,cfg.sparsityH,cfg.options);

%get the best combo of parameters from the test folds based on gradient minimum
testcorr = squeeze(mean(results.testcorr,1));
maxtestcorr = nan(size(testcorr,1),1);

%store the best sparsity (W,H) for each num dimensions
bwh = nan(size(testcorr,1),2);
for k = 1:size(testcorr,1)
    tmp = squeeze(testcorr(k,:,:));
    maxtestcorr(k) = max(tmp(:));
    [bwh(k,1), bwh(k,2)] = find(tmp==max(tmp(:)));
end

%determine gradient minimum & corresponding best sparsity
gradcorr = gradient(maxtestcorr);
bk = find(gradcorr==min(gradcorr));
bw = bwh(bk,1);
bh = bwh(bk,2);
    
% to find best parameters based purely on max
%[bk,bw,bh] = ind2sub(size(testcorr),find(testcorr == max(testcorr(:))));

bestk = results.cfg.dimrange(bk);
bestw = results.cfg.sparsityW(bw);
besth = results.cfg.sparsityH(bh);
bestx = results.x{bk};

%rerun NMF on whole training set with best options
options = cfg.options;
options.x_init.W = bestx.W(:,:,bw,bh);
options.x_init.H = bestx.H(:,:,bw,bh);
options.sW = bestw;
options.sH = besth;

%impute any missing values in training RDM
rdm_train_avg = squeeze(nanmean(rdm_train,1));
if any(isnan(rdm_train_avg(:))), rdm_train_avg = sim_impute(rdm_train_avg,'ultrametric'); end

%get true correlation
truecorr = corr(rdm_hold(:),rdm_train_avg(:));

%run NMF and get holdout correlation
[x,~] = nmf_sc(rdm_train_avg,bestk,options);
mfit = x.W*x.H;
holdoutcorr = corr(mfit(:), rdm_hold(:));
traincorr = corr(mfit(:), rdm_train_avg(:));

%save results
results.holdout.truecorr = truecorr;
results.holdout.holdoutcorr = holdoutcorr;
results.holdout.traincorr = traincorr;
results.holdout.x = x;
results.bestk = bestk;
results.bestw = bestw;
results.besth = besth;

































end

