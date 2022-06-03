function [] = plot_nmf_results_selective(savepath)

rng(10) %set seed

%permutation testing on results
ndim = 10; %this is the max number of dimensions generated, hard-coded
nkit = 5; %the number of tests
nperm = 1000;

bestk = nan(2,nkit);

for exp = 1:2
    
    maxcorr = nan(ndim,nkit);
    randmaxcorr = nan(nperm,ndim,nkit);
    corridx = nan(ndim,nkit);
    
    load(fullfile(savepath, sprintf('exp%d',exp), 'nmf_subsets_selective.mat'),'results','cfg');
    r_sub = results;
    
    %make the indices
    env = cfg.envidx;
    env(env==0.5) = 1; %set driving/unclear videos to outdoors
    stim = cfg.stimlist;
    idx{1} = find(env==1);
    idx{2} = find(env==0);
    idx{3} = find(contains(stim,'Driving'));
    idx{4} = find(contains(stim,'Fighting'));
    idx{5} = find(contains(stim,'Childcare'));
    
    load(fullfile(savepath,sprintf('exp%d',exp), 'nmf_results.mat'),'results');
    W = results.avgcv.holdout.x.W;
 
    for ki = 1:nkit
        
        bestk(exp,ki) = r_sub{ki}.avgcv.bestk;
        
        W1 = r_sub{ki}.avgcv.holdout.x.W;
        subidx = idx{ki};
        
        W0 = W;
        W0(subidx,:) = [];
        
        for i = 1:size(W1,2)
            
            c = 0;
            
            for ii = 1:size(W0,2)
                
                tmp = rankCorr_Kendall_taua(W1(:,i), W0(:,ii));
                
                if tmp>c, c = tmp; maxidx = ii; end
            end
            
            maxcorr(i,ki) = c;
            corridx(i,ki) = maxidx;
            
        end
        
        for xi = 1:nperm
            
            fprintf('%d\n',xi)
            Wrand = W1(randperm(size(W1,1)),:);
            
            for i = 1:size(W1,2)
                
                c = 0;
                
                for ii = 1:size(W0,2)
                    
                    tmp = rankCorr_Kendall_taua(Wrand(:,i),W0(:,ii));
                    
                    if tmp>c, c = tmp; maxidx = ii; end
                end
                
                randmaxcorr(xi,i,ki) = c;
                
            end
            
        end
        
    end
    
    pval = nan(size(maxcorr,1),nkit);
    pvalcorr = pval;
    
    randmax = squeeze(max(max(randmaxcorr,[],2),[],3));
    for i = 1:ndim
        for ii = 1:nkit
            c = maxcorr(i,ii);
            if ~isnan(c)
                tmp = squeeze(randmaxcorr(:,i,ii));
                pval(i,ii) = (sum(tmp>=c)+1)/(nperm+1);
                pvalcorr(i,ii) = (sum(randmax>=c)+1)/(nperm+1);
            end
        end
    end
    
    stats.randmax = randmaxcorr;
    stats.pval = pval;
    stats.pvalcorr = pvalcorr;
    stats.maxcorr = maxcorr;
    stats.maxcorridx = corridx;
    
    save(fullfile(savepath,sprintf('exp%d',exp),'nmf_subsets_selective.mat'),'-append','stats')
    
    plot_stats(exp) = stats;
            
    
end

labels = {'Outdoors','Indoors','Driving', 'Fighting', 'Childcare'};
figure

for i = 1:2
    
    subplot(1,3,i)
    chancelevel = squeeze(nanmean(nanmean(plot_stats(i).randmax,1),2));
    
    cfg = [];
    cfg.scatter = 0;
    cfg.ylabel = 'Kendall''s {\tau}_A';
    if i==1
        cfg.color = [0.5 0.5 0.8];
    else
        cfg.color = [0.5 0.7 0.6];
    end
    cfg.mrksize = 100;
    hold on
    rectangle('Position',[0.1 min(chancelevel) 6 max(chancelevel)-min(chancelevel)],'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none')
    boxplot_jitter_groups(plot_stats(i).maxcorr',labels,cfg)
    
    xlabel('Category removed')
    set(gca,'FontSize',20)
    ylim([0 1])
    set(gca,'ytick',0:0.2:1)
    set(gca,'xgrid','on')
    xtickangle(90)
    title(sprintf('Exp %d', i), 'FontWeight','normal')
    
end

subplot(1,3,3)

cfg = [];
cfg.ylabel = 'Num dimensions';
cfg.scatter = 2;
cfg.mrksize = 100;
cfg.color = {[0.5 0.5 0.8], [0.5 0.7 0.6]};

hold on
line([0.53 1.5], [9 9], 'color', [0.8 0.8 0.9],'LineWidth',4);alpha 0.5
line([1.53 2.5], [10 10], 'color', [0.8 0.9 0.8],'LineWidth',4);alpha 0.5
boxplot_jitter_groups(bestk, {'Exp 1', 'Exp 2'}, cfg)
set(gca,'FontSize',20)
ylim([4 11])
set(gca,'xgrid','on')
xtickangle(90)
            
            
            
            
        
        