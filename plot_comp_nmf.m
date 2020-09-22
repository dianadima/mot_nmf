function [] = plot_comp_nmf(results, frames, savepath)
%plot frames corresponding to each dimension in NMF results
%input: NMF results, cell array of frames from each video, sav

if ~exist(savepath,'dir'), mkdir(savepath); end

ndim = results.bestk;

if ~isfield(results,'holdout')
    k = results.cfg.dimrange==ndim;
    x = results.x{k};
else
    x = results.holdout.x;
end
W = x.W;

%to get H components instead of W
%W = x.H; 

%sort components according to their sum
compsum = sum(W,1);

% %use product of W and H 
% compsum = nan(ndim,1);
% for i = 1:ndim
%     c = x.W(:,i).*x.H(i,:)';
%     compsum(i) = sum(c);
% end

[~, cidx] = sort(compsum,'descend');

for i = 1:ndim
    
    comp = W(:,cidx(i));
    
    %for W&H product
    %comp = x.W(:,cidx(i)).*x.H(cidx(i),:)';
    
    %set a threshold
    t = mean(comp) + 1.5*std(comp);
    idx = find(comp>=t);
    
    %number of plots
    sp = ceil(numel(idx)/2);
    
    %plot above-threshold stimuli
    figure('color','w')
    fig = gcf;
    fig.Units = 'centimeters';
    fig.Position = [5 5 35 10];
    fig.PaperUnits = 'centimeters';
    fig.PaperPosition = [0 0 35 10];
    for f = 1:numel(idx)
        subplot(2,sp,f)
        imshow(frames{idx(f)})
        title(sprintf('%.3f',comp(idx(f))))
    end
    suptitle(sprintf('Dimension %d, sum %.2f, %d > 0.1', i, sum(comp), sum(comp>0.1)))
    
    print(fig,'-r300','-dpng',sprintf(fullfile(savepath,'dim_%d.png'),i))
    close
    
    figure('color','w')
    fig = gcf;
    fig.Units = 'centimeters';
    fig.Position = [5 5 50 12];
    fig.PaperUnits = 'centimeters';
    fig.PaperPosition = [0 0 50 12];
    
    %plot the first and last 30 items
    nit = 30;
    [hlc,hlidx] = sort(comp,'descend');
    for f = 1:nit
            subplot(4,ceil(nit/2),f)
            imshow(frames{hlidx(f)})
            if f==1, ylabel('High'); end
            title(sprintf('%.3f',hlc(f)))
    end
    for f = 1:nit
            subplot(4,ceil(nit/2),nit+f)
            imshow(frames{hlidx(end-f)})
            if f==1, ylabel('Low'); end
            title(sprintf('%.3f',hlc(end-f+1)))
    end
    suptitle(sprintf('Dimension %d, sum %.2f, %d > 0.1', i, sum(comp), sum(comp>0.1)))
    print(fig,'-r300','-dpng',sprintf(fullfile(savepath,'hl_dim_%d.png'),i))
    close



end

