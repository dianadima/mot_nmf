function [results, fitcorr] = run_nmf(rdm, ndim, sparsityW, sparsityH, metric, options)
% run NMF for a specified k (num components) using different sparsity
% parameters (for W and H) & computes the reconstruction accuracy for all

nsW = numel(sparsityW);
nsH = numel(sparsityH);
nid = size(rdm,1);

results.W = nan(nid,ndim,nsW,nsH);
results.H = nan(ndim,nid,nsW,nsH);
results.fitmat = nan(nid,nid,nsW,nsH);
fitcorr = nan(nsW,nsH);

%initialize
[x_init.W, x_init.H] = NNDSVD(abs(rdm), ndim, 0); 
options.x_init = x_init;

for w = 1:nsW
    
    if sparsityW(w)==0
        options.sW = [];
    else
        options.sW = sparsityW(w);
    end
    
    for h = 1:nsH
        
        if sparsityH(h)==0
            options.sH = [];
        else
            options.sH = sparsityH(h);
        end
        
        [x, ~] = nmf_sc(rdm,ndim,options);
        
        results.W(:,:,w,h) = x.W;
        results.H(:,:,w,h) = x.H;
        
        fitm = x.W*x.H;
        
        if strcmp(metric,'kendall')
            fitcorr(w,h) = rankCorr_Kendall_taua(fitm(:), rdm(:));
        elseif strcmp(metric, 'rmse')
           fitcorr(w,h) = sqrt(mean((rdm(:) - fitm(:)).^2))/(mean(rdm(:)));
        elseif strcmp(metric,'pearson')
            fitcorr(w,h) = corr(fitm(:), rdm(:),'rows','pairwise');
        elseif strcmp(metric,'frobenius')
            fitcorr(w,h) = norm(rdm(:) - fitm(:),'fro')^2 / 2 ;
        end

        results.fitmat(:,:,w,h) = fitm;
        
    end
    
end
        

























end