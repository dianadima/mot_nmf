function [vididx1,vididx2] = val_selectmatchingvideos(exp1,exp2)

ncat = 18;
nvid1 = 152;
nvid2 = 65;

category_idx1 = exp1.category_idx;
category_idx2 = exp2.category_idx;
video_category1 = nan(nvid1,1);
video_category2 = nan(nvid2,1);

for i = 1:ncat
    video_category1(category_idx1{i}) = i;
end

for i = 1:ncat
    video_category2(category_idx2{i}) = i;
end

% first select videos from Exp 1 that match Exp 2

vidcorr = nan(nvid2,1);
vididx1 = nan(nvid2,1);

for i = 1:nvid2
    
    vid = exp2.features(i,:);
    categ = video_category2(i);
    
    idx_candidates = find(video_category1==categ); %only from the same action category
    vid1_candidates = exp1.features(idx_candidates,:);
    
    %select the candidate with the max correlation that has not already been selected
    c = corr([vid;vid1_candidates]');
    c = c(1,2:end);
    [cmax,idxmax] = max(c);
    vidx = idx_candidates(idxmax);
    while ismember(vidx,vididx1)
        c(idxmax) = [];
        [cmax,idxmax] = max(c);
        vidx = idx_candidates(idxmax);
    end
    
    vidcorr(i) = cmax;
    vididx1(i) = vidx;
    
end

%select a further balanced set of 65 from Exp 1

vididx2 = nan(65,1);

for i = 1:65 %videoset 2 videos
    
    categ = video_category2(i); %categories should have the same amount of videos as in the previous 2 sets
    
    idx_candidates = find(video_category1==categ);
    
    %remove candidates that have already been selected for previous set
    rm = ismember(idx_candidates,vididx1);
    idx_candidates(rm) = []; 
    
    %select a candidate that has not already been selected
    while ismember(idx_candidates(1),vididx2)
        idx_candidates(1) = [];
    end
    vididx2(i) = idx_candidates(1);

    
end

end