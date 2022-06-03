function [] = val_fasttextfeat(savepath)

if exist(fullfile(savepath,'fasttext_features.mat'),'file')
    
    load(fullfile(savepath,'fasttext_features.mat'),'featmat')
    
else
    
    mdl = fastTextWordEmbedding;
    featmat = nan(2,11,255,300);
    
    for exp = 1:2
        
        load(fullfile(savepath,sprintf('exp%d.mat', exp)),'lbl_resp');
        
        nsub = size(lbl_resp,1);
        ndim = size(lbl_resp,2);
        
        
        for idim = 1:ndim
            
            c = 1; %label counter
            
            for isub = 1:nsub
                
                lbl = strrep(strrep(strrep(lbl_resp{isub,idim},"'",""),'/',','),';',',');
                lbl = split(lbl, ','); %split into different words/phrases
                lbl(strlength(lbl)<2) = []; %remove empty strings due to trailing commas
                
                %for each label given by this subject
                for il = 1:numel(lbl)
                       
                    word = lbl(il);
                    word = strip(word); %remove leading & trailing spaces
                    
                    idx = strfind(word,' '); %are there any multi-word phrases?
                    %cut into words
                    if ~isempty(idx)
                        word = cellstr(split(word,' ')); %get embeddings for all component words
                    end
                    
                    wordvec = word2vec(mdl,word,'IgnoreCase',true);
                    %wordvec = nanmean(wordvec,1); %average if several words
                    
                    if ~isnan(wordvec(1))
                        featmat(exp,idim,c:c+size(wordvec,1),:) = wordvec;
                        c = c+size(wordvec,1);
                    else
                        fprintf('\nNo embedding found for %s, dim%d, sub%d...', word,idim,isub)
                    end
                end
                
            end
        end
    end
    
    save(fullfile(savepath,'fasttext_features.mat'),'featmat')
    
end

featdist = val_analyzefeat(featmat);
save(fullfile(savepath,'fasttext_features.mat'),'-append','featdist')

%see how dimensions relate in embedding space
val_plotsimilarity(featmat)
                
end               