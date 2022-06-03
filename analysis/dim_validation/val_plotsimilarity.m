function [pval,randsim] = val_plotsimilarity(featmat)

%average & concatenate dimensions 
f = squeeze(nanmean(featmat,3)); %average across labels
feat(1:9,:) = f(1,2:10,:);
feat(10:19,:) = f(2,2:11,:);

%distance
fsim = pdist(feat);

%plot
labels_e1 = {'Work','Nature','Cleaning','Children','Eating','Games','Religion','Driving','Reading'};
labels_e2 = {'Chaos','People','Outdoors','Eating','Celebration','Learning','Talking','Working','Chores','Sleeping'};
l = [labels_e1 labels_e2];
plot_rdm(fsim,l,[],1,0)
line([9.5 9.5],[0.5 19.5],'color','w','linewidth',2)
line([0.5 19.5],[9.5 9.5],'color','w','linewidth',2)



end