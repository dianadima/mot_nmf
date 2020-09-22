function [] = plot_parameters_nmf(results, dimrange,sprangeW,sprangeH)

numsW = numel(results.cfg.sparsityW);
sp_label_W = cell(numsW,1);
for i = 1:numsW
    sp_label_W{i} = sprintf('%.1f', results.cfg.sparsityW(i));
end
colors = parula(numsW+1);

for k = 1:numel(dimrange)
    
    traincorr = squeeze(results.traincorr(:,k,:,:));
    testcorr = squeeze(results.testcorr(:,k,:,:));
    
    ndim = dimrange(k);
    corrmtr = squeeze(mean(traincorr,1));
    corretr = squeeze(std(traincorr,[],1));
    
    corrmts = squeeze(mean(testcorr,1));
    correts = squeeze(std(testcorr,[],1));
    
    figure
    subplot(1,2,1)
    hold on
    for i = 1:numel(sprangeW)
        errorbar(sprangeW, corrmtr(i,:),corretr(i,:), 'color',colors(i,:), 'LineWidth',2)
    end
    l = legend(sp_label_W, 'Location','northwest');
    title(l,'Sparsity (W)')
    legend boxoff
    xlim([sprangeH(1)-0.05 sprangeH(end)+0.05])
    grid on
    ylabel('Correlation')
    xlabel('Sparsity (H)')
    box off
    set(gca,'FontSize',14)  
    title(sprintf('%d dimensions (train)', ndim))
    
    subplot(1,2,2)
    hold on
    for i = 1:numel(sprangeW)
        errorbar(sprangeW, corrmts(i,:),correts(i,:), 'color',colors(i,:), 'LineWidth',2)
    end
    l = legend(sp_label_W, 'Location','northwest');
    title(l,'Sparsity (W)')
    legend boxoff
    xlim([sprangeH(1)-0.05 sprangeH(end)+0.05])
    grid on
    ylabel('Correlation')
    xlabel('Sparsity (H)')
    box off
    set(gca,'FontSize',14)  
    title(sprintf('%d dimensions (test)', ndim))
   


end

