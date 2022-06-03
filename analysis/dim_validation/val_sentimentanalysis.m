function [] = val_sentimentanalysis(savepath)

sent.avgscore = nan(2,10);
sent.posrate = nan(2,10);
sent.negrate = nan(2,10);
sent.ntrrate = nan(2,10);
sent.emorate = nan(2,10);


for exp = 1:2
    
    load(fullfile(savepath,sprintf('exp%d.mat', exp)),'lbl_resp');
    
    lbl_resp(:,1) = [];
    ndim = size(lbl_resp,2);
    
    for idim = 1:ndim
        
        dimstr = string(lbl_resp(:,idim)); %skip catch dim
        tkdoc = tokenizedDocument(dimstr);
        nd = numel(tkdoc);
        [cmpS,posS,negS,ntrS] = vaderSentimentScores(tkdoc);
        sent.avgscore(exp,idim) = mean(cmpS);
        sent.posrate(exp,idim) = sum(posS)/nd;
        sent.negrate(exp,idim) = sum(negS)/nd;
        sent.ntrrate(exp,idim) = sum(ntrS)/nd;
        sent.emorate(exp,idim) = (sum(posS)+sum(negS))/nd;
        
    end
    
end
  
save(fullfile(savepath,'sentiment.mat'),'-struct','sent')  

% plot rate of emotional words per dimension
cfg = [];
cfg.scatter = 0;
cfg.ylabel = 'Proportion emotional words';
cfg.color = {[0.5 0.5 0.8], [0.5 0.7 0.6]};
cfg.mrksize = 140;

figure
boxplot_jitter_groups(sent.emorate,{'Exp 1', 'Exp 2'},cfg)
ylim([-0.05 1])
set(gca,'FontSize',20)

% plot rate of positive/negative words per dimension
figure
subplot(1,2,1)
cfg.ylabel = 'Proportion positive';
boxplot_jitter_groups(sent.posrate,{'Exp 1', 'Exp 2'},cfg)
ylim([-0.05 0.7])
set(gca,'FontSize',20)
subplot(1,2,2)
cfg.ylabel = 'Proportion negative';
boxplot_jitter_groups(sent.negrate,{'Exp 1', 'Exp 2'},cfg)
ylim([-0.05 0.7])
set(gca,'FontSize',20)
