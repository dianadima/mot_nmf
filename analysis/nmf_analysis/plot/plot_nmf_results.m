function [] = plot_nmf_results(savepath)

figure

for exp = 1:2
    
    load(fullfile(savepath,sprintf('exp%d',exp), 'nmf_results.mat'),'results','cfg');
    res(exp) = results.avgcv.holdout;
    
    dimrange = cfg.dimrange;
    ndim = numel(dimrange);
    nkit = cfg.kiter;
    nspt = numel(cfg.sparsityW)*numel(cfg.sparsityW);
 
    %average correlations for every step of the cross-validation
    trcorr_inner = nan(nkit,ndim,nspt);
    tscorr_inner = nan(nkit,ndim,nspt);
    trcorr_outer = nan(nkit,ndim);
    tscorr_outer = nan(nkit,ndim);
        
    %get all cross-validation iterations
    for ik = 1:nkit
        %inner k-fold (s): training, test, and true correlation
        trcorr_inner(ik,:,:) = reshape(squeeze(mean(results.kfold{ik}.kfold_sparsity.traincorr,1)),ndim,nspt);
        tscorr_inner(ik,:,:) = reshape(squeeze(mean(results.kfold{ik}.kfold_sparsity.testcorr,1)),ndim,nspt);
        %held-out data (k): training, test, and true correlation
        trcorr_outer(ik,:) = mean(results.kfold{ik}.ndim.traincorr,1);
        tscorr_outer(ik,:) = mean(results.kfold{ik}.ndim.testcorr,1);
    end
    
    %average across CV iterations
    trcorr_inner = squeeze(mean(trcorr_inner,1));
    tscorr_inner = squeeze(mean(tscorr_inner,1));

    subplot(3,1,exp)
    
    hold on    
    plot_time_results(mean(trcorr_inner,2), std(trcorr_inner,[],2), 'time', dimrange, 'color',[0.3 0.7 0.4],'ylim',[],'legend','Training - Inner');
    plot_time_results(mean(tscorr_inner,2), std(tscorr_inner,[],2),'time',dimrange, 'ylim', [],'color',[0.7 0.7 0.2],'legend','Test - Inner');
    plot_time_results(mean(tscorr_outer,1), std(tscorr_outer,[],1),'time',dimrange, 'ylim', [],'color',[0.4 0.6 0.9],'legend','Test - Outer');
    
    grid on
    ylabel('Kendall''s {\tau}_A')
    xlabel('Num dimensions')
    box off
    title('Cross-validation', 'FontWeight','normal')
    set(gca,'FontSize',20)
    xlim([dimrange(1) dimrange(end)])
    
    
end


subplot(3,1,3)
hold on
lc = [0.5 0.5 0.5];
line([0.8 1.2], [res(1).truecorr res(1).truecorr], 'color', lc, 'LineWidth',4);
line([1.4 1.8], [res(2).truecorr res(2).truecorr], 'color', lc, 'LineWidth',4);

cl = [0.5 0.7 0.7; 0.8 0.6 0.5];
h = bar([1 1.6],[[res(1).traincorr; res(2).traincorr] [res(1).holdoutcorr; res(2).holdoutcorr]],'FaceColor','flat','EdgeColor','k');
for k = 1:2
    h(k).CData = cl(k,:);
end
xlim([0.7 1.9])

xticks([1 1.6])
l1 = {'Exp 1', 'Exp 2'};
l2 = {'{\itk}=9', '{\itk}=10'};
labels = [l1;l2];
xticklabels(sprintf('%s\\newline%s\n',labels{:}))

yticks(0:0.2:1)

ylabel('Kendall''s {\tau}_A')
legend(h,{'Training','Test'},'Location','NorthWest')
legend boxoff
box off
set(gca,'ygrid','on')
set(gca,'FontSize',20)

