function [] = val_wordclouds(savepath)

for exp = 1:2
    
    load(fullfile(savepath,sprintf('exp%d.mat', exp)),'lbl_resp','pval');
    
    nsub = size(lbl_resp,1);
    ndim = size(lbl_resp,2);
    
    word_data = nan(ndim,5);
    
    %fix cases where people labeled both ends of a dimension
    ivs = find(contains(lbl_resp,'vs'));
    if ~isempty(ivs)
        for v = 1:numel(ivs)
            tmp = lbl_resp{ivs(v)};
            tmp = string(strrep(tmp,'vs.','vs'));
            tmp = split(tmp, 'vs');
            lbl_resp{ivs(v)} = tmp(1);
        end
    end
    
    wordmat = cell(ndim,1);
    for i = 1:ndim
        tmp = [];
        for ii = 1:nsub
            lbl = strrep(strrep(strrep(lbl_resp{ii,i},"'",""),'/',','),';',',');
            if ii == 1
                tmp = strcat(tmp, lower(lbl));
            else
                tmp = strcat(tmp, ',', lower(lbl));
            end
        end
        wordmat{i} = char(tmp);
    end
    
    %plot wordclouds
    figure;
    wc = wordcloud(wordmat{1});
    word_data(1,:) = wc.SizeData(1:5)./size(lbl_resp,1);
    close; clear wc
    
    figure
    for i = 2:ndim
        if exp==2
            subplot(1,10,i-1)
        else
            subplot(1,9,i-1)
        end
        if pval(i)<=0.005
            wc = wordcloud(wordmat{i},'HighlightColor','k');
        else
            wc = wordcloud(wordmat{i},'HighlightColor',[0.5 0.5 0.5]);
        end
        word_data(i,:) = wc.SizeData(1:5)./size(lbl_resp,1);
    end
    save(fullfile(savepath,sprintf('exp%d.mat', exp)),'-append','word_data');
    %print(gcf,'-r300','-dtiff',fullfile(sprintf('%s%d',tg,expi),sprintf('wordcloud_%d.tiff',i-1)))
end 