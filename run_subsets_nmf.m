function [results] = run_subsets_nmf(rdm,cfg)

szrange = cfg.szrange;
nsz = numel(szrange);
nit = cfg.szreps;
nid = size(rdm,1);
results = cell(nsz,nit);

for s = 1:nsz
    
    sz = szrange(s);
    fprintf('\nEstimating dimensions for %d elements...', sz);
    
    dimrange = cfg.dimrange;
    %make sure we don't use a num dim higher than num items
    if any(dimrange>=sz)
        dimrange = dimrange(1:find(dimrange>=sz,1)-1);
    end
    
    for i = 1:nit
        
        fprintf('\n%d',i)
        
        idx = randperm(nid,sz);
        subrdm = rdm(idx,:,:);
        
        res = run_kfold_nmf(subrdm,dimrange,cfg.kfold,cfg.sparsityW,cfg.sparsityH,cfg.options);
        res.subset_idx = idx;
        
        results{s,i} = res;
        
    end
    
end
        
        




























end