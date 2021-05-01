function [results] = run_subsets_categ_nmf(rdm,cfg)
% leave out action categories and rerun NMF procedure to check how
% dimensionality changes as a function of number of actions
% note - only for Experiment 1 (hard-coded category index)

%number of stimuli per category (8, assumes equal distribution)
nc = 8;

szrange = cfg.szrange; %here, num categories to leave out
nsz = numel(szrange);
nit = cfg.szreps;      %number of iterations for each stage
nid = size(rdm,2);
results = cell(nsz,nit);

catidx = 1:nc:nid;
ncat = numel(catidx);

for s = 1:nsz
    
    sz = szrange(s); %number of categ to leave out
    fprintf('\nEstimating dimensions for %d elements...', sz);
    
    %make sure we don't use a num dim higher than num items
    dimrange = cfg.dimrange;
    if any(dimrange>=(nid-(sz*nc)))
        dimrange = dimrange(1:find(dimrange>=(nid-(sz*nc)),1)-1);
    end
    
    for i = 1:nit
        
        fprintf('\n%d',i)
        
        idx = randperm(ncat,sz); %draw random categories
        cidx = [];
        for ci = 1:numel(idx)
            cidx = [cidx catidx(idx(ci)):(catidx(idx(ci))+(nc-1))]; %get item indices to leave out
        end
        
        %remove items
        idx = 1:nid; 
        idx(cidx) = []; 
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