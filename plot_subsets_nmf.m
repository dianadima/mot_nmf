function [] = plot_subsets_nmf(results, cfg)
%plot num of dimensions as function of subset size

subrange = cfg.szrange;

nsub = size(results,1);
nitr = size(results,2);

%extract the best train and test corr
traincorr = nan(nsub,nitr);
testcorr = nan(nsub,nitr);
truecorr = nan(nitr,1);
ktrain = nan(nsub,nitr);
ktest = nan(nsub,nitr);

for itr = 1:nitr
        
    for sub = 1:nsub
        
        r = results{sub,itr};
        truecorr(itr) = r.truecorr(1);

%         %%% max correlation         
%         tr = squeeze(mean(r.traincorr,1));
%         [trk,~,~] = ind2sub(size(tr),find(tr == max(tr(:))));
%         traincorr(sub,itr) = max(tr(:));
%         ktrain(sub,itr) = r.cfg.dimrange(trk);
% 
%         ts = squeeze(mean(r.testcorr,1));
%         [tsk,~,~] = ind2sub(size(ts),find(ts == max(ts(:))));
%         testcorr(sub,itr) = max(ts(:));
%         ktest(sub,itr) = r.cfg.dimrange(tsk);
%         
        
        %%% min gradient
        tr = gradient(squeeze(mean(r.traincorr,1)));
        [trk,~,~] = ind2sub(size(tr),find(tr == min(tr(:))));
        traincorr(sub,itr) = min(tr(:));
        ktrain(sub,itr) = r.cfg.dimrange(trk);

        ts = gradient(squeeze(mean(r.testcorr,1)));
        [tsk,~,~] = ind2sub(size(ts),find(ts == min(ts(:))));
        testcorr(sub,itr) = min(ts(:));
        ktest(sub,itr) = r.cfg.dimrange(tsk);
        
    end
    
end
        
        
%now plot them: training corr, test corr, both errors
figure
subplot(1,2,1); hold on
errorbar(subrange, mean(ktrain,2), std(ktrain,[],2), 'color','k', 'LineWidth',2)
errorbar(subrange, mean(ktest,2),  std(ktest,[],2),  'color','r', 'LineWidth',2)
plot(subrange, mode(ktest,2), 'o', 'MarkerSize',10, 'MarkerFaceColor','w','MarkerEdgeColor','r', 'LineWidth',2)
grid on
xticks(subrange)
ylabel('Num dimensions')
xlabel('Dataset size')
box off
set(gca,'FontSize',18)
xlim([subrange(1)-2 subrange(end)+2])

subplot(1,2,2); hold on
errorbar(subrange, mean(traincorr,2), std(traincorr,[],2), 'color','k', 'LineWidth',2);
errorbar(subrange, mean(testcorr,2),  std(testcorr,[],2), 'color','r', 'LineWidth',2);
legend({'Training','Test'}); legend boxoff
grid on
xticks(subrange)
ylabel('Correlation')
xlabel('Dataset size')
box off
set(gca,'FontSize',18)
xlim([subrange(1)-2 subrange(end)+2])

