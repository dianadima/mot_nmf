function [results] = run_ndim_nmf(rdm, dimrange, sparsityW, sparsityH, metric, options) 
% run through the range of k (num components) provided and run NMF on each
% with different sparsity parameters

nid = size(rdm,1);
ndim = numel(dimrange);
fitcorr = nan(ndim,numel(sparsityW),numel(sparsityH));
fitmat = nan(nid,nid,numel(sparsityW),numel(sparsityH),ndim);
x = cell(ndim,1);


for d = 1:ndim
    
    fprintf('\nRunning NMF with %d dimensions...', dimrange(d))
    
    [dx, dfitcorr] = run_nmf(rdm,dimrange(d), sparsityW, sparsityH, metric, options);
    
    x{d}.W = dx.W;
    x{d}.H = dx.H;
    
    fitcorr(d,:,:) = dfitcorr;
    fitmat(:,:,:,:,d) = dx.fitmat;
    
end


results.x = x;
results.fitcorr = fitcorr;
results.fitmat = fitmat;
















end