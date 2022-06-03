function [nmfcorr] = plot_featurecorrs(datapath,savepath)

nmfcorr = struct;
nprm = 100; %number of randomizations

for exp = 1:2
    
    load(fullfile(datapath, sprintf('exp%d',exp), 'video_features_rdm.mat'),'models','modelnames');
    load(fullfile(savepath, sprintf('exp%d',exp), 'nmf_results.mat'),'results','cfg');
    
    % load and sort dimensions
    W = results.avgcv.holdout.x.W;
    compsum = sum(W,1);
    [~,cidx] = sort(compsum,'descend');
    ndim = size(W,2);
    nvid = size(W,1);
    
    % select and sort feature RDMs
    midx = [6 8 9 10 11 14 17 15 16 13 12];
    models = models(:,midx);
    modelnames = modelnames(midx);
    nmod = size(models,2);
    
    % make individual action category models
    act_mod = squareform(models(:,contains(modelnames,'Action category')));
    categ = unique(act_mod,'rows')';
    for a = 1:size(categ,2)
        action_models(:,a) = pdist(categ(:,a));
    end
    
    
    % initialize results   
    model_corr = nan(ndim,nmod+1);
    model_corrR = nan(nprm,ndim,nmod+1);
    model_pval = nan(ndim,nmod+1);
    
    % prep randomization indices
    randidx = nan(nvid,nprm);
    for p = 1:nprm
        randidx(:,p) = randperm(nvid);
    end

    for d = 1:ndim
        
        fprintf('\nRunning dim %d for exp %d...\n',d,exp)
        
        % get dimension RDM
        drdm = pdist(W(:,cidx(d)))';
        
        % get feature RDM correlations
        for m = 1:nmod
            model_corr(d,m) = rankCorr_Kendall_taua(drdm, models(:,m));
        end
        
        % get maximal correlation with any of the individual action categories
        mc = 0;
        for a = 1:size(action_models,2)
            c = rankCorr_Kendall_taua(drdm,action_models(:,a));
            if c > mc, mc = c; end
        end
        model_corr(d,m+1) = mc;
        
        % randomization testing
        for p = 1:nprm
            
            drdmR = pdist(W(randidx(:,p),cidx(d)))';
            
            for m = 1:nmod
                model_corrR(p,d,m) = rankCorr_Kendall_taua(drdmR, models(:,m));
            end
            
            mc = 0;
            for a = 1:size(action_models,2)
                c = rankCorr_Kendall_taua(drdmR,action_models(:,a));
                if c > mc, mc = c; end
            end
            model_corrR(p,d,m+1) = mc;
            
        end

    end

randmax = squeeze(max(max(model_corrR,[],3),[],2));
for d = 1:ndim
    for m = 1:nmod+1
        model_pval(d,m) = (sum(randmax>=model_corr(d,m))+1)/(nprm+1);
    end
end

modelnames = [modelnames {'Individual actions'}];

save(fullfile(savepath,sprintf('exp%d',exp),'nmf_featurecorr.mat'),'model_corr','model_pval','randmax','modelnames')

nmfcorr(exp).corr = model_corr;
nmfcorr(exp).pval = model_pval;
nmfcorr(exp).randmax = randmax;
nmfcorr(exp).modelnames = modelnames;

end

%create custom colormap and get colors for stacked barplots
cmap(1,:) = [0.5 0.7 0.6];
cmap(2,:) = [0.4 0.5 0.7];
cmap(3,:) = [1 0.95 0.9];
[X,Y] = meshgrid([1:3],[1:50]);  %// mesh of indices
cmap = interp2(X([1,25,50],:),Y([1,25,50],:),cmap,X,Y);
colors = cmap(1:4:50,:); colors(3,:) = [];
clear cmap X Y

%legend marker size
bsize = [10 10 10];

%now plot
figure
for exp = 1:2
    
    subplot(2,1,exp)
    hold on
    
    b = bar(abs(nmfcorr(exp).corr),0.4,'stacked','facecolor','flat');
    for i = 1:numel(b)
        b(i).CData = colors(i,:);
    end
    
    %rmax = max(nmfcorr(exp).randmax);
    %line([0.5 11.5], [rmax rmax], 'color', [0.7 0.7 0.7], 'LineWidth', 2);
    
    box off
    set(gca,'FontSize',20)
    set(gca,'ygrid','on')
    yticks(0:0.2:1)
    ylabel('Abs Kendall''s {\tau}_A')
    xticks(1:size(nmfcorr(exp).corr,1))
    xlim([0.5 10.5])
    
    if exp==1
        h = legend(b(1:6),modelnames(1:6),'FontSize',11);
    else
        h = legend(b(7:12),modelnames(7:12),'FontSize',11);
        xlabel('Dimension');
    end
    
    h.ItemTokenSize = bsize;
    legend boxoff
    
end

%add figure panel text box
annotation(gcf,'textbox',...
    [0.00984955752212389 0.454545454545455 0.105194690265487 0.534290271132377],...
    'String',{'A','','','','','','','','','','B'},...
    'LineStyle','none',...
    'FontSize',26,...
    'FontName','Arial',...
    'FitBoxToText','off');


end
    
    

