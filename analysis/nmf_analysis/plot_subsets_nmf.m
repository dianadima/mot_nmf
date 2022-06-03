function [] = plot_subsets_nmf(results, cfg)
%plot num of dimensions as function of subset size

if isfield(cfg, 'szrange')
    subrange = cfg.szrange;
else
    subrange = 1:size(results,1);
end

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
        
        % get elbow point in training data
        tr = squeeze(mean(r.traincorr,1));
        [~,trk] = get_elbowpoint(tr,0);
        traincorr(sub,itr) = tr(trk);
        ktrain(sub,itr) = r.cfg.dimrange(trk);
        
        ts = squeeze(mean(r.testcorr,1));
        [~,tsk] = get_elbowpoint(ts,0);
        
        testcorr(sub,itr) = ts(tsk);
        ktest(sub,itr) = r.cfg.dimrange(tsk);
        
    end
    
end
        
        
%now plot them
hold on
errorbar(subrange, mean(ktrain,2), std(ktrain,[],2), 'color',[0.4 0.4 0.4], 'LineWidth',2)
errorbar(subrange, mean(ktest,2),  std(ktest,[],2),  'color',[0.3 0.7 0.7], 'LineWidth',2)
grid on
xticks(subrange)
ylabel('Num dimensions')
xlabel('Dataset size')
box off
set(gca,'FontSize',18)
xlim([subrange(1)-2 subrange(end)+2])
ylim([0 25])
legend({'Training','Test'}); legend boxoff