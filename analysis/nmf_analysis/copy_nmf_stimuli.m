function [nvid] = copy_nmf_stimuli(dim,stimpath,targetpath)

%copies & renames videos corresponding to each dimension
%place them together so that participants can't tell which is which if they poke around

ndim = numel(dim);
nvid = nan(ndim,2);

for id = 1:ndim
    
    dimname = sprintf('dim%02.f',id);
    dimdir = fullfile(targetpath,dimname);
    if ~exist(dimdir,'dir'), mkdir(dimdir); end
    
    nvid_a = numel(dim(id).high);
    for iv = 1:nvid_a
        copyfile(fullfile(stimpath,[dim(id).high{iv} '.mp4']), fullfile(dimdir,[sprintf('%02.f',iv) '.mp4']));
        fprintf('\nCopied video %d out of %d\n', iv, nvid_a);
    end
    
    nvid_b = numel(dim(id).low);
    for iv = 1:nvid_b
        copyfile(fullfile(stimpath,[dim(id).low{nvid_b-iv+1} '.mp4']), fullfile(dimdir,[sprintf('%02.f',nvid_a+iv) '.mp4'])); %save in inverse order
        fprintf('\nCopied video %d out of %d\n', iv, nvid_b);
    end
    
    
    nvid(id,1) = nvid_a;
    nvid(id,2) = nvid_b;

end

end