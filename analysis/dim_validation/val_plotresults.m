function [] = val_plotresults(savepath)

%plot average accuracy per dimension
avgacc = nan(2,11);
for exp = 1:2   
    load(fullfile(savepath,sprintf('exp%d.mat', exp)),'acc');   
    acc(:,1) = []; %remove catch dimension
    avgacc(exp,1:size(acc,2)) = mean(acc,1);
end

[~,stats_acc.p,stats_acc.ci,stats_acc.stats] = ttest2(avgacc(1,:),avgacc(2,:),'vartype','unequal');
 
load(fullfile(savepath,'fasttext_features.mat'),'featdist');

cfg = [];
cfg.scatter = 0;
cfg.ylabel = 'Proportion correct';
cfg.color = {[0.5 0.5 0.8], [0.5 0.7 0.6]};
cfg.chance = 0.125;
cfg.mrksize = 140;
labels = {'Exp 1', 'Exp 2'};

figure
subplot(1,2,1)
boxplot_jitter_groups(avgacc,labels,cfg)
ylim([0 1])
set(gca,'FontSize',20)
title('Odd-one-out','FontWeight','normal')

cfg.mrksize = 140;
cfg.chance = max(featdist.acrossdim_frq(:));
cfg.ylabel = 'Proportion participants';

data = squeeze(max(featdist.withindim_frq,[],3));
data(1,10) = NaN;
[~,stats_lbl.p,stats_lbl.ci,stats_lbl.stats] = ttest2(data(1,:),data(2,:),'vartype','unequal');

subplot(1,2,2)
boxplot_jitter_groups(data,{'Exp 1','Exp 2'},cfg)
ylim([0 1])
set(gca,'FontSize',20)
title('Labeling','FontWeight','normal')

save(fullfile(savepath,'validation_stats.mat'),'stats_acc','stats_lbl')

%plot dimensions ranked according to accuracy
labels_e1 = {'Work','Nature','Cleaning','Children','Eating','Games','Religion','Driving','Reading'};
labels_e2 = {'Chaos','People','Outdoors','Eating','Celebration','Learning','Talking','Working','Chores','Sleeping'};
figure

d1 = [avgacc(1,1:9)' data(1,1:9)'];
[~,sortidx] = sort(avgacc(1,1:9),'descend');
l = reordercats(categorical(labels_e1),labels_e1);

subplot(1,2,1)
hold on
b = bar(l,d1(sortidx,:),'grouped','FaceColor','flat');
b(1).FaceColor = [0.5 0.5 0.7];
b(2).FaceColor = [0.8 0.6 0.5];
set(gca,'FontSize',20)
ylabel('Accuracy/ % agreeement')
title('Exp 1','FontWeight','normal')
set(gca,'Ygrid','on')

d2 = [avgacc(2,1:10)' data(2,1:10)'];
[~,sortidx] = sort(avgacc(2,1:10),'descend');
l = reordercats(categorical(labels_e2),labels_e2);

subplot(1,2,2)
b = bar(l,d2(sortidx,:),'grouped','FaceColor','flat');
b(1).FaceColor = [0.5 0.5 0.7];
b(2).FaceColor = [0.8 0.6 0.5];
title('Exp 2','FontWeight','normal')
set(gca,'FontSize',20)
legend('Odd-one-out accuracy','Label agreement')
legend box off
box off
set(gca,'Ygrid','on')

end

