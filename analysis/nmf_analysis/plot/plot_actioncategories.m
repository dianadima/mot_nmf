function [] = plot_actioncategories(datapath, savepath)
%bubble plot showing how nmf dimensions map onto action categories
%with semantic labels from validation experiments

labels_e1 = {'Work','Nature','Cleaning','Children','Eating','Games','Religion','Driving','Reading'};
labels_e2 = {'Chaos','People','Outdoors','Eating','Celebration','Learning','Talking','Working','Chores','Sleeping'};

dim_idx = {[1 2 4 5 9],[8 3 7 4 6]};
%dim_idx = {[3 6 7 8],[1 2 5 9 10]}; %supplementary

for exp = 1:2
    
    load(fullfile(datapath, sprintf('exp%d',exp), 'video_features.mat'),'categories','categories_idx');
    load(fullfile(savepath, sprintf('exp%d',exp), 'nmf_results.mat'),'results','cfg');

    dim = results.avgcv.holdout.x.W; 
    [~,idx] = sort(sum(dim,1),'descend'); 
    dim = dim(:,idx);

    catidx = categories_idx; 
    cat = categories;
    l = cell(size(dim,1),1);
    for i = 1:numel(cat) 
        l(catidx{i}) = deal(cat(i)); 
    end

    dimavg = nan(numel(cat),size(dim,2));
    for i = 1:numel(cat)
        dimavg(i,:) = mean(dim(catidx{i},:),1);
    end

    subplot(1,2,f)
    hold on
    col = inferno(30-exp); col(17:26,:)=[];
    
    for i = 1:numel(dim_idx{exp})

        x = repmat(i,1,20-exp);
        y = 1:20-exp;

        sz = dimavg(:,dim_idx{exp}(i))';
        sz = (sz-min(sz))/(max(sz)-min(sz));

        [~,idx] = sort(sz,'ascend');
        c(idx,:) = col;

        bc = bubblechart(x,y,sz,c);
        bubblesize([3 30])
        bc.MarkerEdgeColor = 'k';
        bc.LineWidth = 1.5;
        bc.MarkerFaceAlpha = 0.9;
        clear bc c

    end

    if exp==2
        blgd = bubblelegend('Avg weight','Style','horizontal');
        blgd.Location = 'northoutside';
        blgd.NumBubbles = 2;
        blgd.Box = 'off';
    end

    set(gca, 'YDir','reverse')
    yticks(1:20-exp)
    yticklabels(cat)
    xticks(1:numel(dim_idx{exp}))
    if exp==1
        xticklabels(labels_e1(dim_idx{exp}))
    else
        xticklabels(labels_e2(dim_idx{exp}))
    end
    set(gca,'FontSize',20)
    set(gca,'XGrid','on')
    set(gca,'YGrid','on')

end
