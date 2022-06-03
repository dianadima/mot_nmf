function [fdist] = val_analyzefeat(featmat)

%hard-coded dimensions
ndim = 11;
nsub = 51;
nlbl = nsub*5;

%within experiment: 
dmat = nan(2,ndim,nlbl,nlbl);                  %distances between labels *for each dimension*
cmat = nan(2,ndim,ndim-1,nlbl,nlbl);           %distances *across dimensions*

%remove catch dim
%featmat(:,1,:,:) = [];

for exp = 1:2
    
    vmat = squeeze(featmat(exp,:,:,:)); %10,255,embedding size

   for idim = 1:ndim
        
        dim_mat = squeeze(vmat(idim,:,:)); %255 by emb size
        d = pdist(dim_mat);%,'cosine');
        d = squareform(d);
        d(tril(true(size(d)))) = NaN;
        dmat(exp,idim,:,:) = d;
        
        vmat_leftout = vmat;
        vmat_leftout(idim,:,:) = [];
        
        for ii = 1:ndim-1
            
            dim_mat1 = squeeze(vmat_leftout(ii,:,:));
            d = pdist([dim_mat;dim_mat1]);%,'cosine');
            d = squareform(d);
            d = d(1:nlbl,nlbl+1:nlbl*2);
            cmat(exp,idim,ii,:,:) = d;
        end
        
    end

end

%thresh = nanmean(dmat(:)) - 2*nanstd(dmat(:)); %#ok<*NANSTD,*NANMEAN>
dmat_orig = dmat; %keep catch dimension in case it's useful, but remove from the freq computations
dmat(:,1,:,:) = [];
cmat_orig = cmat; cmat(:,1,:,:,:) = []; cmat(:,:,1,:,:) = [];
thresh = prctile(dmat(:),10);
fdist.thresh = thresh;

% summarize
fdist.withindim_avg = nanmean(dmat,4); %for each label, whats the average distance to other labels?
fdist.withindim_frq = sum(dmat<=thresh,4)./nsub; %note: proportion takes into account subjects only regardless of how many labels they gave

fdist.withindim_mat = dmat_orig;

fdist.acrossdim_avg = nanmean(nanmean(cmat,5),4); %mean distance of each dimension from each other dimension
fdist.acrossdim_frq = sum(sum(cmat<=thresh,5),4)./(nsub*nsub);
fdist.acrossdim_mat = cmat_orig;

%remove catch dim
featmat(:,1,:,:) = [];
ndim = ndim-1;

%across experiments
fdist.acrossexp_avg = nan(ndim-1,ndim);
fdist.acrossexp_frq = nan(ndim-1,ndim,nlbl);
fdist.acrossexp_mat = nan(ndim-1,ndim,nlbl,nlbl);

for i = 1:ndim-1
    for ii = 1:ndim
        
        vmat1 = squeeze(featmat(1,i,:,:));     
        vmat2 = squeeze(featmat(2,ii,:,:));
        
        vmat1(isnan(sum(vmat1,2)),:) = []; 
        vmat2(isnan(sum(vmat2,2)),:) = []; 
        
        nlbl1 = size(vmat1,1);
        nlbl2 = size(vmat2,1);
        
        dmat = squareform(pdist([vmat1;vmat2]));%,'cosine'));
        dmat = dmat(1:nlbl1,nlbl1+1:nlbl1+nlbl2);
  
        fdist.acrossexp_avg(i,ii) = mean(dmat(:));
        fdist.acrossexp_frq(i,ii,1:nlbl1) = (sum(dmat,2)<=thresh)/nlbl2;
        fdist.acrossexp_mat(i,ii,1:nlbl1,1:nlbl2) = dmat;
    end
end




% f = permute(featmat, [4 3 2 1 5]);
% f(:,:,1,:,:) = [];
% f = reshape(f,[5100 768]);
% dmat = pdist(f);
% dsq = squareform(dmat);
% 
% exp_idx = [1 5100/2+1];
% dim_idx = 1:255:5100;
% sub_idx = 1:5:5100;
% 
% thresh = nanmean(dmat(:)) - 2*nanstd(dmat(:));

            
            