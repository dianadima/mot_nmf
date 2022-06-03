function [] = val_bertfeat(savepath)

if exist(fullfile(savepath,'bert_features.mat'),'file')
    
    load(fullfile(savepath,'bert_features.mat'),'featmat')
    
else
    
    mdl = bert;
    tokenizer = mdl.Tokenizer;
    featmat = nan(2,11,255,768);
    
    for exp = 1:2
        
        load(fullfile(savepath,sprintf('exp%d.mat', exp)),'lbl_resp');
        
        nsub = size(lbl_resp,1);
        ndim = size(lbl_resp,2);
        
        
        for idim = 1:ndim
            
            c = 0; %label counter
            
            for isub = 1:nsub
                
                lbl = strrep(strrep(strrep(lbl_resp{isub,idim},"'",""),'/',','),';',',');
                lbl = split(lbl, ','); %split into different words/phrases
                lbl(strlength(lbl)<2) = []; %remove empty strings due to trailing commas
                
                %for each label given by this subject
                for il = 1:numel(lbl)
                    
                    c = c+1;
                    
                    word = lbl(il);
                    word = strip(word); %remove leading & trailing spaces
                    
                    %wordmat{idim,lblcount} = word;
                    
                    btoken = encode(tokenizer,word);
                    feat = bert.model(btoken{1},mdl.Parameters); %features from last layer
                    feat = extractdata(feat); %num feat x num tokens
                    
                    featmat(exp,idim,c,:) = mean(feat,2);
                end
                
            end
        end
    end
    
    save(fullfile(savepath,'bert_features.mat'),'featmat')
    
end

featdist = val_analyzebertfeat(featmat);
save(fullfile(savepath,'bert_features.mat'),'-append','featdist')

                
end               
                
                
                
                
                