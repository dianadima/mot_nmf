function [results] = run_kfold_nmf(rdm,dimrange,k,sparsityW,sparsityH,options)

%run cross-validation separately for each stimulus pair
nvid = size(rdm,2);
rdmnan = ~isnan(rdm);
rdmsum = squeeze(sum(rdmnan,1));

%get indices per pairs
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
 
ndim = numel(dimrange);
results.truecorr = nan(k,1);
results.sparsity = nan(k,ndim,2);
results.traincorr = nan(k,ndim,numel(sparsityW),numel(sparsityH));
results.testcorr = nan(size(results.traincorr));

%fold loop
for kf = 1:k
    
    rdm1 = nan(size(rdmsum));
    rdm2 = nan(size(rdmsum));
    
    %get indices per pairs
    for i = 1:nvid
        rdm1(i,i) = 0;
        rdm2(i,i) = 0;
        for j = i+1:nvid
            if rdmsum(i,j)>=k
                
                cvp = cvpart{i,j};
                
                idx = find(~isnan(rdm(:,i,j)));
                idx1 = idx(cvp(:,kf)==0);
                idx2 = idx(cvp(:,kf));

                %average observations in training & test rdms for each fold
                rdm1(i,j) = nanmean(rdm(idx1,i,j));
                rdm1(j,i) = nanmean(rdm(idx1,j,i));
                
                rdm2(i,j) = nanmean(rdm(idx2,i,j));
                rdm2(j,i) = nanmean(rdm(idx2,j,i));
                
            else
                %if there are not enough obs, all get assigned to training
                rdm1(i,j) = nanmean(rdm(:,i,j));
                rdm1(j,i) = nanmean(rdm(:,j,i));
            end
        end
    end
                
    
    fprintf('\nRunning iteration %d out of %d\n', kf, k)
    %impute any missing values for each RDM
    if any(isnan(rdm1(:))), rdm1 = sim_impute(rdm1,'ultrametric'); end
    if any(isnan(rdm2(:))), rdm2 = sim_impute(rdm2,'ultrametric'); end
    
    %true correlation
    results.truecorr(kf) = corr(rdm1(:), rdm2(:));
    
    %run NMF (search through num dimensions & sparsity parameters)
    kres = run_ndim_nmf(rdm1,dimrange,sparsityW, sparsityH, options);
    
    %get test correlation
    results.traincorr(kf,:,:,:) = kres.fitcorr;
    for d = 1:ndim
        for w = 1:numel(sparsityW)
            for h = 1:numel(sparsityH)
                mfit = squeeze(kres.fitmat(:,:,w,h,d));
                mcorr = corr(mfit(:),rdm2(:));
                results.testcorr(kf,d,w,h) = mcorr;
            end
        end
    end
    
    %save results for one fold
    if kf==1, results.x = kres.x; end %save the matrices for 1st fold
    
end

%save
results.cfg.cvpart = cvpart;
results.cfg.dimrange = dimrange;
results.cfg.sparsityW = sparsityW;
results.cfg.sparsityH = sparsityH;
results.cfg.kfold = k;































end