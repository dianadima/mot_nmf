function [] = val_readdata(datapath,savepath)

for exp = 1:2
      
    data = readtable(fullfile(datapath,sprintf('exp%d_data.xls',exp)));
    ndim = 9 + exp; %one extra dimension in exp 2; includes catch dimension
    
    nsub = size(data,1);    
    ntrl = 20;
    
    varnames = data.Properties.VariableNames;
    data = table2cell(data);
    
    sel_resp = nan(nsub,ndim,ntrl);
    lbl_resp = cell(nsub,ndim);
    sel_odd1 = nan(nsub,ndim,ntrl); %the actual odd-one-out for each trial
    sel_resp_binary = zeros(nsub,ndim,ntrl);
    %age = nan(nsub,1);
    
    vid_repeats = zeros(nsub,ndim,45); %how many repeats for each video in odd-one-out task
    
    %get column indices
    idx_seltrl = find(contains(varnames,'select_trl'));
    idx_selvid = find(contains(varnames,'select_vid'));
    idx_selrsp = find(contains(varnames,'select_response'));
    idx_lbltrl = find(contains(varnames,'label_trl'));
    idx_lblrsp = find(contains(varnames,'label_response'));
    
    for isub = 1:nsub
        
        %save responses on odd-one-out task
        seltrl = strsplit(data{isub,idx_seltrl},',','CollapseDelimiters',false)';
        selvid = strsplit(data{isub,idx_selvid},',','CollapseDelimiters',false)';
        selrsp = strsplit(data{isub,idx_selrsp},',','CollapseDelimiters',false)';
        selrsp = cellfun(@(x) str2num(x), selrsp)+1; %Matlab indexing
        
        idxv1 = 1;
        dimtrlcount = zeros(ndim,1);
        
        for i = 1:numel(seltrl)
            
            trl = char(seltrl(i));
            nd = str2num(trl(end-1:end))+1;
            dimtrlcount(nd) = dimtrlcount(nd)+1; %count trials for each dimension
            
            if i<numel(seltrl)
                
                nexttrl = char(seltrl(i+1));
                nextd = [nexttrl(end-1:end) '/'];
                
                %find the next dimension, discarding the trials we already saw
                %make sure to get the correct index by adding #of discarded vids
                %works with diff numbers of videos per trial
                idxv2 = find(contains(selvid(idxv1:end),nextd),1) + idxv1-1;
                
                %bit clunky - adjust manually for case in which same dimension
                %follows (by moving the req number of videos onwards)
                
                if idxv2==idxv1
                    
                    idxv2 = idxv1+8;

                end
            else
                idxv2 = numel(selvid)+1;
            end
            
            trlvid = selvid(idxv1:idxv2-1);
            idxv1 = idxv2;
            
            trlvid = cellfun(@(x) str2num(x(9:10)),trlvid); %actual video numbers
            vid_repeats(isub,nd,trlvid) = vid_repeats(isub,nd,trlvid)+1;
            [corr_resp,corr_idx] = max(trlvid); %video number and video idex
            sel_odd1(isub,nd,dimtrlcount(nd)) = corr_resp; %the correct video number
            sel_resp(isub,nd,dimtrlcount(nd)) = trlvid(selrsp(i)); %saves the actual video number selected
            sel_resp_binary(isub,nd,dimtrlcount(nd)) = selrsp(i)==corr_idx; %checks the video index
            
        end
        
        %save responses on labeling task
        lbltrl = strsplit(data{isub,idx_lbltrl},',','CollapseDelimiters',false)'; %#ok<*FNDSB>
        lblrsp = strsplit(data{isub,idx_lblrsp},"','",'CollapseDelimiters',false)';
        
        for i = 1:numel(lbltrl)
            trl = char(lbltrl(i));
            nd = str2num(trl(end-1:end))+1; %#ok<*ST2NM>
            lbl_resp{isub,nd} = char(lblrsp(i));
        end
        
        %save age (for original datafiles)
        %age(isub) = data{isub,contains(varnames,'age')};
        
    end
    
    % compute accuracy
    acc = squeeze(sum(sel_resp_binary,3))./20;
    
    idx_exclude = find(acc(:,1)<=0.125); %exclude participants who perform at/below chance
    if exp==1 %add exclusions based on looking at the word labels
        idx_exclude(end+1) = 27; %#ok<*AGROW>
    else
        idx_exclude(end+1) = 1;
    end
    
    acc(idx_exclude,:) = [];
    lbl_resp(idx_exclude,:) = [];  
    
    %get pvalues
    acc1 = acc-0.125;
    pval = nan(ndim,1);
    for i = 1:ndim
        pval(i) = signrank(acc1(:,i));
    end
    
    %randomization testing
    [~,~,~, pval_omnibus_corr] = randomize_rho(acc1);
    
    cfg = [];
    cfg.scatter = 0;
    cfg.ylabel = 'Proportion correct';
    cfg.color = [0.6 0.6 0.6]; %[0.5 0.6 0.7];
    cfg.chance = 0.125;
    cfg.mrksize = 80;
    labels = 1:ndim;
    
    subplot(1,2,exp)
    boxplot_jitter_groups(acc',labels,cfg)
    set(gca,'FontSize',18)
    hold on
    for d = 1:ndim
        if pval_omnibus_corr(d)<=0.005
            text(d-0.05, 1.1, '*' ,'FontSize',14)
        end
    end
    xticklabels(gca,{'Catch',1:ndim-1})
    title(sprintf('Exp %d', exp),'FontWeight','normal')
    
    save(fullfile(datapath,sprintf('exp%d_data.mat', exp)),'idx_exclude','sel_*','lbl_*');
    save(fullfile(savepath,sprintf('exp%d.mat', exp)),'acc','pval*','lbl_resp');
    clearvars -except datapath savepath
end



end