function [] = plot_holdout_nmf(results)

dimrange = results.cfg.dimrange;
ndim = numel(dimrange);

%find the best correlation for each number of dimensions
trcorr = nan(size(results.testcorr,1), ndim);
tscorr = nan(size(trcorr));
for i = 1:ndim
    t = squeeze(mean(results.testcorr(:,i,:,:),1));
    [idx1,idx2] = find(t==max(t(:)));
    trcorr(:,i) = squeeze(results.traincorr(:,i,idx1,idx2));
    tscorr(:,i) = squeeze(results.testcorr(:,i,idx1,idx2));
end

gtcorr = results.truecorr;

%training correlation
figure
subplot(1,3,1); hold on
plot_time_results(mean(trcorr,1), std(trcorr,[],1),'time',dimrange, 'ylim', []);
%errorbar(dimrange, mean(trcorr,1), std(trcorr,[],1), 'color','k', 'LineWidth',2)
grid on
ylabel('Correlation')
xlabel('Num dimensions')
box off
title('Training', 'FontWeight','normal')
set(gca,'FontSize',18)
xlim([dimrange(1)-1 dimrange(end)+1])

%test correlation
subplot(1,3,2); hold on
%rectangle('Position',[dimrange(1)-1 min(gtcorr) dimrange(end)+1 max(gtcorr)-min(gtcorr)], 'FaceColor',[0.8 0.85 0.95],'EdgeColor','w')
line ([dimrange(1)-1 dimrange(end)+1], [mean(gtcorr) mean(gtcorr)], 'color', [0.4 0.6 0.8], 'LineWidth', 2)
plot_time_results(mean(tscorr,1), std(tscorr,[],1),'time',dimrange, 'ylim', []);
%errorbar(dimrange, mean(tscorr,1),  std(tscorr,[],1),  'color','k', 'LineWidth',2)
grid on
ylabel('Correlation')
xlabel('Num dimensions')
box off
title('Test', 'FontWeight','normal')
set(gca,'FontSize',18)
xlim([dimrange(1)-1 dimrange(end)+1])

%gradient
subplot(1,3,3); hold on
plot(dimrange, gradient(mean(tscorr,1)),  'color','k', 'LineWidth',2)
grid on
ylabel('Correlation gradient')
xlabel('Num dimensions')
box off
title('Test', 'FontWeight','normal')
set(gca,'FontSize',18)
xlim([dimrange(1)-1 dimrange(end)+1])


end
