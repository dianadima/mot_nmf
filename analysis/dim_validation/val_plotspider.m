function [] = val_plotspider(savepath) 

load(fullfile(savepath,'fasttext_features.mat'),'featdist');

a = 1 - featdist.acrossexp_avg;
a = (a-min(a(:)))/(max(a(:))-min(a(:)));
%numplots = sum(max(a,[],1)>=prctile(a(:),90));

labels_e1 = {'Work','Nature','Cleaning','Children','Eating','Games','Religion','Driving','Reading'};
labels_e2 = {'Chaos','People','Outdoors','Eating','Celebration','Learning','Talking','Working','Chores','Sleeping'};

colors = [0.5 0.5 0.9;
    0.2 0.7 0.4;
    0.7 0.3 0.4
    0.8 0.5 0.3;
    0.5 0.5 0.5;
    0.7 0.7 0.4;
    0.3 0.5 0.8;
    0.5 0.5 0.9;
    0.2 0.7 0.4;
    0.7 0.3 0.4];

figure
count = 0;
for i = 1:numel(labels_e2)
    
    dmat = a(:,i)';
    
    %if max(dmat)>=prctile(a(:),90)
        
        count = count+1;
        
     %  subplot(2,ceil(numplots/2),count)
        figure
        spider_plot(dmat,...
            'AxesDisplay','data',...
            'AxesLabelsEdge','none',...
            'AxesLabels',labels_e1,...
            'FillOption','on',...
            'FillTransparency',0.1,...
            'Color',colors(i,:),...
            'AxesFontSize',14,...
            'LabelFontSize',16,...
            'AxesLabelsOffset',0.2,...
            'AxesLimits',repmat([0;1],1,size(dmat,2))); 
        legend(labels_e2(i),'Location','bestoutside')
        legend boxoff
        set(gca,'FontSize',20)
        %print(labels_e2{i},'-dpng','-r300')
        
    %end
    
end

end