function [dimensions] = plot_comp_nmf(results, frames, savepath, stimlist, thresh)
% plot frames corresponding to each dimension in NMF results
% input: results: NMF results struct
%        frames: cell array of frames from each video
%        savepath: path to save figures
%        stimlist: list of stimulus names (can be empty)
%        thresh: how to threshold highest & lowest videos
%            percent, 10% of videos
%            top8, top 8 & bottom 8
%            top10, top 10 & bottom 10
%            stdev, 1.5*1SD from mean
% output: structure with filenames (if stimlist provided)

if ~exist(savepath,'dir'), mkdir(savepath); end

%we only need the final results
if isfield(results,'avgcv')
    results = results.avgcv;
end

% get the number of dimensions
ndim = results.bestk; 
fprintf('\nPlotting %d components\n', ndim)

% get the final W matrix
x = results.holdout.x;
W = x.W;

dimensions = struct;

% sort components according to their sum
compsum = sum(W,1);
[~, cidx] = sort(compsum,'descend');

if strcmp(thresh,'percentile')
    t1 = prctile(W(:),90);
    t2 = prctile(W(:),10);
end

for i = 1:ndim
    
    comp = W(:,cidx(i));
    
    if strcmp(thresh,'stdev')
        t1 = mean(comp) + 1.5*std(comp);
        t2 = mean(comp) - 1.5*std(comp);
    end
    
    figure('color','w')
    fig = gcf;
    fig.Units = 'centimeters';
    fig.Position = [0 0 60 10];
    fig.PaperUnits = 'centimeters';
    fig.PaperPosition = [0 0 60 10];
    
    % plot the first and last items
    
    if strcmp(thresh,'percent') %top 10%
        nit1 = floor(0.1*numel(comp));
        nit2 = nit1;
    elseif strcmp(thresh,'top8') %top 8 vids
        nit1 = 8; 
        nit2 = 8;
    elseif strcmp(thresh,'top10') %top 10 vids
        nit1 = 10; 
        nit2 = 10;
    else %get number of videos based on threshold
        nit1 = sum(comp>t1);
        nit2 = sum(comp<t2);
    end

    [ha, ~] = tight_subplot(2,max(nit1,nit2),[0 0],[0 0],[0 0]);
    [~,hlidx] = sort(comp,'descend');
    
    % high-weighted
    for f = 1:nit1
            axes(ha(f));
            imshow(frames{hlidx(f)})
            %if f==1, ylabel('High'); end
    end
    
    % low-weighted
    for f = 1:nit2
            axes(ha(max(nit1,nit2)+f))
            imshow(frames{hlidx(end-f+1)})
            %if f==1, ylabel('Low'); end
    end
    print(fig,'-r300','-dtiff',sprintf(fullfile(savepath,'dim%d.png'),i))
    
    % save the filenames of top and bottom videos for each dimension
    if ~isempty(stimlist)
        dimensions(i).high = stimlist(hlidx(1:nit1));
        dimensions(i).low = stimlist(hlidx(end-nit2+1:end));
    end



end

end