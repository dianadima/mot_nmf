function [results] = run_subsets_nmf(rdm,cfg)
%subsamples n stimuli x k iterations and runs k-fold CV on each subset to select best num dimensions and sparsity for each subset

szrange = cfg.szrange; %dataset sizes to test
nsz = numel(szrange);
nit = cfg.szreps;      %number of iterations 
nid = size(rdm,2);
results = cell(nsz,nit);

for s = 1:nsz
    
    sz = szrange(s);
    fprintf('\nEstimating dimensions for %d elements...', sz);
    
    %make sure we don't use a num dim higher than num items
    dimrange = cfg.dimrange;
    if any(dimrange>=sz)
        dimrange = dimrange(1:find(dimrange>=sz,1)-1);
    end
    
    for i = 1:nit
        
        fprintf('\n%d',i)
        
        %randomly select stimuli
        idx = randperm(nid,sz);
        subrdm = rdm(:,idx,idx);
        
        %no final hold-out, just nested CV if we have several sparsity parameters to test
        if numel(cfg.sparsityW)>1||numel(cfg.sparsityH)>1 
            fprintf('\nRunning nested CV...\n')
            res = run_kfold_nested_nmf(subrdm,dimrange,cfg.kfold,cfg.sparsityW,cfg.sparsityH,cfg.options,cfg.cvscheme,cfg.metric);
        else
            fprintf('\nRunning simple CV...\n') %kfold CV if only testing dimensionality
            res = run_kfold_nmf(subrdm,dimrange,cfg.kfold,cfg.sparsityW,cfg.sparsityH,cfg.options,cfg.cvscheme,cfg.metric);
        end
        res.subset_idx = idx;
        
        results{s,i} = res;
        
    end
    
end
        
        




























end