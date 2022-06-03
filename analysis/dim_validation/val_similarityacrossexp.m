function [fsim,pval,randsim] = val_similarityacrossexp(featmat)

%dimension labels for plotting
labels_e1 = {'Work','Nature','Cleaning','Children','Eating','Games','Religion','Driving','Reading'};
labels_e2 = {'Chaos','People','Outdoors','Eating','Celebration','Learning','Talking','Working','Chores','Sleeping'};

%experiment colors
c1 = [0.5 0.5 0.8];
c2 = [0.5 0.7 0.6];

%randomization
nperm = 5000;
featmat(:,1,:,:) = []; %remove catch dim

%average & concatenate dimensions 
f = squeeze(nanmean(featmat,3)); %average across labels: 2*10*300
feat(1:9,:) = f(1,1:9,:);
feat(10:19,:) = f(2,:,:);

%randomize
randsim = nan(nperm,10,9);
for i = 1:nperm

    frand = randperm(19);
    %fmap = squeeze(featmat(2,:,:,:));
    %fmap = reshape(fmap,[],300);
    %fmap = fmap(frand,:);
    %fmap = reshape(fmap,[10 255 300]);
    
   % fmap = squeeze(f(2,:,:));
    fmap = feat(frand,:); 
    fsim = pdist(fmap);
    fsim = squareform(fsim);
    fsim = fsim(10:19,1:9);
    randsim(i,:,:) = fsim;
   % randsim(i,:,:) = 1-(fsim-min(fsim(:)))/(max(fsim(:))-min(fsim(:)));
   % clear feat fsim

end



% feat(1:9,:) = f(1,1:9,:);
% feat(10:19,:) = f(2,:,:);

%distance matrix plotting
fsim = pdist(feat);
dmat = (fsim - min(fsim))/(max(fsim)-min(fsim));
dmat = squareform(dmat);
Y = tsne(dmat,'Algorithm','exact','Distance','euclidean');

figure
subplot(1,2,1)
plot_rdm(dmat,[labels_e1 labels_e2],[],1,0)
ax = gca;
for i = 1:9 
    ax.YTickLabel{i} = sprintf('\\color[rgb]{%f,%f,%f}%s',c1, ax.YTickLabel{i});
    ax.XTickLabel{i} = sprintf('\\color[rgb]{%f,%f,%f}%s',c1, ax.XTickLabel{i});
end
for i = 10:numel(ax.YTickLabel)
    ax.YTickLabel{i} = sprintf('\\color[rgb]{%f,%f,%f}%s',c2, ax.YTickLabel{i});
    ax.XTickLabel{i} = sprintf('\\color[rgb]{%f,%f,%f}%s',c2, ax.XTickLabel{i});
end

subplot(1,2,2)
hold on
colors = [repmat([0.5 0.5 0.8],9,1); repmat([0.5 0.7 0.6],10,1)];
t = textscatter(Y,[labels_e1 labels_e2],'ColorData',colors,'TextDensityPercentage',100);
t.FontSize = 16;
set(gca,'FontSize',20)
box off
yticks([])
xticks([])
set(gca,'XColor','none')
set(gca,'YColor','none')

%panel label textboxes
annotation(figure1,'textbox',...
    [0.0164888673765731 0.894230769230769 0.104517909002904 0.0865384615384616],...
    'String','A','LineStyle','none','FontSize',26,'FontName','Arial','FitBoxToText','off');
annotation(figure1,'textbox',...
    [0.531493707647629 0.891826923076924 0.104517909002904 0.0865384615384616],...
    'String','B','LineStyle','none', 'FontSize',26,'FontName','Arial','FitBoxToText','off');

% matrix including only cross-experiment similarities
fsim = squareform(fsim);
fsim = fsim(10:19,1:9);

pval = nan(size(fsim));
for i = 1:size(fsim,1)
    for ii = 1:size(fsim,2)
        pval(i,ii) = (sum(randsim(:,i,ii)<=fsim(i,ii)))/(nperm+1);
    end
end

%normalize and convert to similarity
fsim = 1-(fsim-min(fsim(:)))/(max(fsim(:))-min(fsim(:)));

%normalize
%fsim = (fsim-min(fsim(:)))/(max(fsim(:))-min(fsim(:)));

%plot
figure
imagesc(fsim)
colormap(viridis)
xticklabels(labels_e1)
yticklabels(labels_e2)
set(gca,'FontSize',20)
for i = 1:size(fsim,1)
    for ii = 1:size(fsim,2)
        if pval(i,ii)<=1 %rdm(mi,mj)>=0.1 %
                text(ii,i, sprintf('%.02f',fsim(i,ii)),'Color','w','FontSize',10,'HorizontalAlignment','center');
        end
    end
end

c = colorbar;
c.Label.String = 'Euclidean distance';
        



end