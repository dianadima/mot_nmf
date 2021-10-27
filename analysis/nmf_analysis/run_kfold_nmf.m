function [results] = run_kfold_nmf(rdm,dimrange,k,sparsityW,sparsityH,options,cvscheme,metric)
%runs a k-fold CV on the rdm, results are averaged across folds

% partition pairwise (Exp 1)
if strcmp(cvscheme,'pairwise')
    
    %count ratings for each stimulus pair
    nvid = size(rdm,2);
    rdmnan = ~isnan(rdm);
    rdmsum = squeeze(sum(rdmnan,1));
    
    %partition the indices for each pair
    cvpart = cell(size(rdmsum));
    for i = 1:nvid
        for j = i+1:nvid
            if rdmsum(i,j)>=k
                cvp = cvpartition(rdmsum(i,j),'kfold',k);
                for kf = 1:k
                    cvpart{i,j}(:,kf) = cvp.test(kf);
                end
            end
        end
    end

% partition subjectwise (Exp 2)
elseif strcmp(cvscheme,'subjectwise')
    nsub = size(rdm,1);
    cvpart = cvpartition(nsub,'kfold',k);
end

ndim = numel(dimrange);
results.truecorr = nan(k,1);
results.sparsity = nan(k,ndim,2);
results.traincorr = nan(k,ndim,numel(sparsityW),numel(sparsityH));
results.testcorr = nan(size(results.traincorr));

%fold loop
for kf = 1:k
    
    if strcmp(cvscheme,'subjectwise')
        
        %select and average folds
        rdm1 = rdm(cvpart.training(kf),:,:); rdm1 = squeeze(nanmean(rdm1,1));
        rdm2 = rdm(cvpart.test(kf),:,:); rdm2 = squeeze(nanmean(rdm2,1));
        
    elseif strcmp(cvscheme,'pairwise')
        
        %deal fairly with pairs with not enough data
        %this is not an issue with our final set of N=300
        if mod(kf,2)==0, assignvar = 1; else, assignvar = 2; end
        
        rdm1 = nan(size(rdmsum));
        rdm2 = nan(size(rdmsum));
        
        %get indices per pairs
        for i = 1:nvid
            rdm1(i,i) = 1; %SIMILARITY MATRIX - initialize diagonal
            rdm2(i,i) = 1; %SIMILARITY MATRIX - initialize diagonal
            for j = i+1:nvid
                if rdmsum(i,j)>=k
                    
                    cvp = cvpart{i,j};
                    
                    %split the indices according to cvpartition object
                    idx = find(~isnan(rdm(:,i,j)));
                    idx1 = idx(cvp(:,kf)==0);
                    idx2 = idx(cvp(:,kf));
                    
                    %average observations in training & test rdms for each fold
                    rdm1(i,j) = nanmean(rdm(idx1,i,j));
                    rdm1(j,i) = nanmean(rdm(idx1,j,i));
                    
                    rdm2(i,j) = nanmean(rdm(idx2,i,j));
                    rdm2(j,i) = nanmean(rdm(idx2,j,i));
                    
                else
                    %if there are not enough obs, split them equally
                    %order of assignment changes with fold
                    if assignvar==1
                        rdm1(i,j) = nanmean(rdm(:,i,j));
                        rdm1(j,i) = nanmean(rdm(:,j,i));
                        assignvar = 2;
                    elseif assignvar==2
                        rdm2(i,j) = nanmean(rdm(:,i,j));
                        rdm2(j,i) = nanmean(rdm(:,j,i));
                        assignvar = 1;
                    end
                end
            end
        end
        
    end
                
    fprintf('\nRunning iteration %d out of %d\n', kf, k)
    
    %impute any missing values for each RDM - only for Exp 1
    num_nans1 = 0; num_nans2 = 0;
    if any(isnan(rdm1(:))) 
        fprintf('\n %.3f NaNs found in training rdm\n', sum(isnan(rdm1(:)))/numel(rdm1)); 
        num_nans1 = sum(isnan(rdm1(:)))/2; 
        rdm1 = sim_impute(rdm1,'ultrametric',1); 
    end
    if any(isnan(rdm2(:)))
        fprintf('\n %.3f NaNs found in test rdm\n', sum(isnan(rdm2(:)))/numel(rdm2)); 
        num_nans2 = sum(isnan(rdm2(:)))/2; 
        rdm2 = sim_impute(rdm2,'ultrametric',1); 
    end
    
    %true correlation
    if strcmp(metric,'kendall')
        results.truecorr(kf) = rankCorr_Kendall_taua(rdm1(:), rdm2(:));
    elseif strcmp(metric, 'rmse')
        results.truecorr(kf) = sqrt(mean((rdm2(:) - rdm1(:)).^2))/(mean(rdm2(:)));
    elseif strcmp(metric,'pearson')
        results.truecorr(kf) = corr(rdm1(:), rdm2(:),'rows','pairwise');
    elseif strcmp(metric,'frobenius')
        results.truecorr = norm(rdm2(:) - rdm1(:),'fro')^2 / 2 ;
    end
    
    %run NMF (search through num dimensions & sparsity parameters)
    kres = run_ndim_nmf(rdm1,dimrange,sparsityW, sparsityH, metric, options);
    
    %get test correlation
    results.traincorr(kf,:,:,:) = kres.fitcorr;
    for d = 1:ndim
        for w = 1:numel(sparsityW)
            for h = 1:numel(sparsityH)
                mfit = squeeze(kres.fitmat(:,:,w,h,d));
                
                if strcmp(metric,'kendall')
                    mcorr = rankCorr_Kendall_taua(mfit(:), rdm2(:));
                elseif strcmp(metric, 'rmse')
                    mcorr = sqrt(mean((rdm2(:) - mfit(:)).^2))/(mean(rdm2(:)));
                elseif strcmp(metric,'pearson')
                    mcorr = corr(mfit(:), rdm2(:),'rows','pairwise');
                elseif strcmp(metric,'frobenius')
                    mcorr = norm(rdm2(:) - mfit(:),'fro')^2 / 2 ;
                end
                
                results.testcorr(kf,d,w,h) = mcorr;
            end
        end
    end
    
    %save results for one fold - will be used to initialize retraining
    if kf==1, results.x = kres.x; end
    results.num_missing_values(kf,:) = [num_nans1 num_nans2];
    
end

%save
results.cfg.cvpart = cvpart;
results.cfg.dimrange = dimrange;
results.cfg.sparsityW = sparsityW;
results.cfg.sparsityH = sparsityH;
results.cfg.kfold = k;































end