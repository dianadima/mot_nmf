function [D] = sim_impute(D, method)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
switch method
    
    case 'mean'
        %replace with mean distance rating of those 2 videos from other videos
        
        [id1,id2] = find(isnan(D));
        for i = 1:numel(id1)
            idx1 = id1(i); idx2 = id2(i);
            D(idx1,idx2) = nanmean([D(idx1,:) D(idx2,:)]);
        end
        
    case 'ultrametric'
        %replace with lowest maximum distance from other videos
        
        [id1,id2] = find(isnan(D));
        
        for i = 1:numel(id1)
            
            c = max(D(:));
            idx1 = id1(i); idx2 = id2(i);
            
            if isnan(D(idx1,idx2)) %we are replacing things symmetrically
                
                for ii = 1:size(D,1)
                    
                    if ~any(isnan([D(idx1,ii) D(ii,idx2)])) && ~ismember(ii, [idx1 idx2])
                        
                        m = max([D(idx1,ii) D(ii, idx2)]);
                        if m<c
                            c = m;
                        end
                    end
                end
                
                D(idx1, idx2) = c;
                D(idx2, idx1) = c;
                
            end
        end
        
end
        




end

