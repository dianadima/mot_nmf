function [res] = run_kfold_nested_nmf(rdm,dimrange,k,sparsityW,sparsityH,options,cvscheme,metric)
% holds out a third of data for selecting the number of dimensions
% runs kfold CV on the other two thirds of the data for selecting sparsity parameters 
% this procedure is run several times and the final number of dimensions is
% selected based on the average of holdout data across these iterations

if strcmp(cvscheme,'pairwise')
    
    %leave out 1/3 observations per pair
    nvid = size(rdm,2);
    rdmnan = ~isnan(rdm);
    rdmsum = squeeze(sum(rdmnan,1));
    rdm_hold = nan(size(rdmsum));
    rdm_train = rdm;
    for i = 1:nvid
        rdm_hold(i,i) = 1; %FOR SIMILARITY MATRIX
        for j = i+1:nvid
            if rdmsum(i,j)>2
                
                nhold = floor(rdmsum(i,j)/3);
                
                pairvec = rdm(:,i,j);
                idx = shuffle(find(~isnan(pairvec)));
                holdidx = idx(1:nhold);
                
                rdm_hold(i,j) = mean(rdm(holdidx,i,j));
                rdm_hold(j,i) = mean(rdm(holdidx,j,i));
                
                rdm_train(holdidx,i,j) = NaN;
                rdm_train(holdidx,j,i) = NaN;
                
            end
        end
    end

    
elseif strcmp(cvscheme,'subjectwise')
    
    nsub = size(rdm,1);
    holdout_prc = 0.2;
    holdout_num = floor(holdout_prc*nsub);
    holdout_idx = randperm(nsub,holdout_num);
    rdm_hold = rdm(holdout_idx,:,:);
    rdm_hold = squeeze(nanmean(rdm_hold,1));
    
    rdm_train = rdm;
    rdm_train(holdout_idx,:,:) = [];
    
end

ndim = numel(dimrange);
num_holdout_nan = 0;
num_train_nan = 0;

%impute missing values from holdout data 
if any(isnan(rdm_hold(:))), num_holdout_nan = sum(isnan(rdm_hold(:)))/2; rdm_hold = sim_impute(rdm_hold,'ultrametric',1); end

results = run_kfold_nmf(rdm_train,dimrange,k,sparsityW,sparsityH,options,cvscheme,metric);
testcorr = squeeze(mean(results.testcorr,1)); %average across folds
sW = nan(ndim,1); sH = nan(ndim,1);
for i = 1:ndim
    tmp = squeeze(testcorr(i,:,:));  
    if strcmp(metric,'rmse') || strcmp(metric,'frobenius') %we are minimizing the error
        [sW(i), sH(i)] = find(tmp==min(tmp(:)));
    else %maximize the correlation
        [sW(i),sH(i)] = find(tmp==max(tmp(:)));
    end
end

res.kfold_sparsity = results; %store inner CV results

%impute any missing values in average training RDM
rdm_train_avg = squeeze(nanmean(rdm_train,1));
if any(isnan(rdm_train_avg(:))), num_train_nan = sum(isnan(rdm_hold(:)))/2; rdm_train_avg = sim_impute(rdm_train_avg,'ultrametric',1); end

if strcmp(metric,'kendall')
    truecorr = rankCorr_Kendall_taua(rdm_hold(:),rdm_train_avg(:));
elseif strcmp(metric, 'rmse')
    truecorr = sqrt(mean((rdm_hold(:) - rdm_train_avg(:)).^2))/(mean(rdm_hold(:)));
elseif strcmp(metric,'pearson')
    truecorr = corr(rdm_hold(:),rdm_train_avg(:),'rows','pairwise');
elseif strcmp(metric,'frobenius')
    truecorr = norm(rdm_hold(:) - rdm_train_avg(:),'fro')^2 / 2 ;
end

res.ndim.truecorr = truecorr;
res.ndim.training_nan = num_train_nan;
res.ndim.holdout_nan = num_holdout_nan;

%now apply the selected sparsity parameters at every k to the held out 1/3rd of data
for i = 1:ndim
    
    options.x_init.W = results.x{i}.W(:,:,sW(i),sH(i));
    options.x_init.H = results.x{i}.H(:,:,sW(i),sH(i));
    options.sW = sparsityW(sW(i));
    options.sH = sparsityW(sH(i));
    
     %run NMF and get holdout correlation
    [x,~] = nmf_sc(rdm_train_avg,dimrange(i),options);
    mfit = x.W*x.H;
    
    if strcmp(metric,'kendall')
        testcorr = rankCorr_Kendall_taua(mfit(:), rdm_hold(:));
        traincorr = rankCorr_Kendall_taua(mfit(:), rdm_train_avg(:));
    elseif strcmp(metric, 'rmse')
        testcorr = sqrt(mean((rdm_hold(:) - mfit(:)).^2))/(mean(rdm_hold(:)));
        traincorr = sqrt(mean((rdm_train_avg(:) - mfit(:)).^2))/(mean(rdm_train_avg(:)));
    elseif strcmp(metric,'pearson')
        testcorr = corr(mfit(:), rdm_hold(:),'rows','pairwise');
        traincorr = corr(mfit(:), rdm_train_avg(:),'rows','pairwise');
    elseif strcmp(metric,'frobenius')
        testcorr = norm(rdm_hold(:) - mfit(:),'fro')^2 / 2 ;
        traincorr = norm(rdm_train_avg(:) - mfit(:),'fro')^2 / 2 ;
    end
    
    %save results
    res.ndim.testcorr(i) = testcorr;
    res.ndim.traincorr(i) = traincorr;
    res.ndim.x{i} = x;
    res.ndim.bestw(i) = options.sW;
    res.ndim.besth(i) = options.sH;


end

    

    





end

