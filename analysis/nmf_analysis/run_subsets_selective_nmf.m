function [results] = run_subsets_selective_nmf(rdm,cfg)
%selectively remove: 1.indoor videos 2.outdoor videos 3.driving 4.fighting 5.childcare
%recompute the number of dimensions and the dimensions themselves and correlate with the full-set 9 dim ones

nid = size(rdm,2);
ntests = 5;
results = cell(ntests,1);

% cfg contains env (indoors/outdoor labels) and stimlist (stimulus names based on action categories)
% the RDM and labels are sorted the same (alphabetically)
env = cfg.envidx;
env(env==0.5) = 1; %set driving/unclear videos to outdoors

stim = cfg.stimlist;
labels = {'Outdoors','Indoors','Driving', 'Fighting', 'Childcare'};

idx = cell(ntests,1);
idx{1} = find(env==1); 
idx{2} = find(env==0);
idx{3} = find(contains(stim,'Driving'));
idx{4} = find(contains(stim,'Fighting'));
idx{5} = find(contains(stim,'Childcare'));

%save the original range of dimensions
dimrange_orig = cfg.dimrange;

for it = 1:ntests
    
    fprintf('\nEstimating dimensions without %s videos...', labels{it});
    
    %remove the corresponding videos
    subidx = 1:nid; 
    subidx(idx{it}) = [];
    
    %adjust the range of dimensions: make sure we don't use a num dim higher than num items
    dimrange = dimrange_orig;
    if any(dimrange>=numel(subidx))
        dimrange = dimrange(1:find(dimrange>=numel(subidx),1)-1);
    end

    %subsample RDM
    subrdm = rdm(:,subidx,subidx);
    
    % run NMF
    cfg.dimrange = dimrange;
    results{it} = run_holdout_nested_nmf(subrdm,cfg);
    results{it}.subidx = subidx;
        
end


    
end