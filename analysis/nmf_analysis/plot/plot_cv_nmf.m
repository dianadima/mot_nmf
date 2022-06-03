function [] = plot_cv_nmf(results,cfg,varargin)
% plot: - cross-validation curves for (1) training, (2) test-inner, (3) test-outer
%       - test performance curves for all sparsity parameters (test-inner)
% inputs: NMF results
%         NMF cfg
%         optional: number of dimensions for plotting sparsity parameters (otherwise best k is chosen)

dimrange = cfg.dimrange;
ndim = numel(dimrange);
nkit = cfg.kiter;
nspt = numel(cfg.sparsityW)*numel(cfg.sparsityW);

if isempty(varargin)
    ncomp = results.avgcv.bestk;
else
    ncomp = varargin{1};
end


%average correlations for every step of the cross-validation
trcorr_inner = nan(nkit,ndim,nspt);
tscorr_inner = nan(nkit,ndim,nspt);
gtcorr_inner = nan(nkit,1);
trcorr_outer = nan(nkit,ndim);
tscorr_outer = nan(nkit,ndim);
gtcorr_outer = nan(nkit,1);

%get all cross-validation iterations
for ik = 1:nkit
    
    %inner k-fold (s): training, test, and true correlation
    trcorr_inner(ik,:,:) = reshape(squeeze(mean(results.kfold{ik}.kfold_sparsity.traincorr,1)),ndim,nspt);
    tscorr_inner(ik,:,:) = reshape(squeeze(mean(results.kfold{ik}.kfold_sparsity.testcorr,1)),ndim,nspt);
    gtcorr_inner(ik) = mean(results.kfold{ik}.kfold_sparsity.truecorr);
    
    %held-out data (k): training, test, and true correlation 
    trcorr_outer(ik,:) = mean(results.kfold{ik}.ndim.traincorr,1);
    tscorr_outer(ik,:) = mean(results.kfold{ik}.ndim.testcorr,1);
    gtcorr_outer(ik) = mean(results.kfold{ik}.ndim.truecorr);
    
end

%save the inner test correlation
ts = tscorr_inner;

%average across CV iterations
trcorr_inner = squeeze(mean(trcorr_inner,1));
tscorr_inner = squeeze(mean(tscorr_inner,1));

%plot overall CV curves
figure
subplot(1,2,1)
hold on

rectangle('Position',[dimrange(1)-1 min(gtcorr_inner) dimrange(end)+1 max(gtcorr_inner)-min(gtcorr_inner)], 'FaceColor',[0.8 0.8 0.8],'EdgeColor','w')
plot_time_results(mean(trcorr_inner,2), std(trcorr_inner,[],2), 'time', dimrange, 'color',[0.3 0.7 0.4],'ylim',[],'legend','Training - Inner');
plot_time_results(mean(tscorr_inner,2), std(tscorr_inner,[],2),'time',dimrange, 'ylim', [],'color',[0.7 0.7 0.2],'legend','Test - Inner');
plot_time_results(mean(tscorr_outer,1), std(tscorr_outer,[],1),'time',dimrange, 'ylim', [],'color',[0.4 0.6 0.9],'legend','Test - Outer');

grid on
ylabel('Kendall''s {\tau}_A')
xlabel('Num dimensions')
box off
title('Cross-validation', 'FontWeight','normal')
set(gca,'FontSize',16)
xlim([dimrange(1) dimrange(end)])

%plot example of sparsity curves for one k
subplot(1,2,2)
k = find(dimrange==ncomp);
plot_parameters(ts,k,cfg)
set(gca,'Fontsize',16)

    %plot sparsity parameter curves
    function [] = plot_parameters(testcorr,k,cfg)
        
        sprangeW = cfg.sparsityW;
        sprangeH = cfg.sparsityH;
        sp_label_W = cell(numel(sprangeW),1);
        for i = 1:numel(sprangeW)
            sp_label_W{i} = sprintf('%.1f', cfg.sparsityW(i));
        end
        colors = viridis(numel(sprangeW)+2);
        
        testcorr = squeeze(testcorr(:,k,:));
        testcorr = reshape(testcorr, size(testcorr,1), numel(sprangeW), numel(sprangeH));
        
        corrmts = squeeze(mean(testcorr,1));
        correts = squeeze(std(testcorr,[],1));
        
        hold on
        for i = 1:numel(sprangeW)
            %legend for extremes only
            if i==1
                h1 = errorbar(sprangeW, corrmts(i,:),correts(i,:), 'color',colors(i,:), 'LineWidth',2);
            elseif i==numel(sprangeW)
                h2 = errorbar(sprangeW, corrmts(i,:),correts(i,:), 'color',colors(i,:), 'LineWidth',2);
            else
                errorbar(sprangeW, corrmts(i,:),correts(i,:), 'color',colors(i,:), 'LineWidth',2)
            end
        end
        
        l = legend([h1,h2],{sp_label_W{1},sp_label_W{end}}, 'Location','northeast');
        title(l,'Sparsity (W)')
        legend boxoff
        xlim([sprangeH(1)-0.05 sprangeH(end)+0.05])
        xticks(sprangeH)
        grid on
        xlabel('Sparsity (H)')
        box off
        set(gca,'FontSize',14)
        title(sprintf('%d dimensions (test-inner)', cfg.dimrange(k)),'FontWeight','normal')
        
        
        
    end




end
