function [] = val_dimensionmapping(nmfpath,savepath)

rng(10)
savefile = fullfile(savepath,'dimension_mapping.mat');

p1 = fullfile(nmfpath,'exp1','nmf_results.mat');
p2 = fullfile(nmfpath,'exp2','nmf_results.mat');

%load and sort reconstructed NMF dimensions
load(p1,'results'); dim1 = results.avgcv.holdout.x.W; [~,idx] = sort(sum(dim1,1),'descend'); dim1 = dim1(:,idx);
load(p2,'results'); dim2 = results.avgcv.holdout.x.W; [~,idx] = sort(sum(dim2,1),'descend'); dim2 = dim2(:,idx);

%load features
load(fullfile(savepath,'video_features.mat'),'exp1','exp2');

%get indices for videosets
if ~isfield(exp1,'vididx1')
    [vididx1, vididx2] = val_selectmatchingvideos(exp1, exp2);
else
    vididx1 = exp1.vididx1;
    vididx2 = exp1.vididx2;
end

nvid = 65; 
ndim1 = 9; 
ndim2 = 10;
figure
%% learn regression between features and dimensions

%test two sets of features
for featset = 1:2

    if featset==1

        subset1 = exp1.features(vididx1,:); %Exp 1 matching subset
        subset2 = exp1.features(vididx2,:); %Exp 1 second subset
        subset3 = exp2.features;            %Exp 2

    else

        subset1 = exp1.clip(vididx1,:);
        subset2 = exp1.clip(vididx2,:);
        subset3 = exp2.clip;

    end

    subdim1 = dim1(vididx1,:);
    subdim2 = dim1(vididx2,:);
    subdim3 = dim2;

    dimP = nan(3,nvid,ndim2); %within E1, E1-E2, E2-E1

    %regression lambdas to search through
    lambdas = logspace(-5,5,20);

    %train regression on Exp1 matching set, predict Exp1 second set,Exp2

    for i = 1:ndim1

        %cross-validate to find best lambda on training set
        lmcv = fitrlinear(subset1,subdim1(:,i),'Regularization','lasso','Learner','leastsquares','Solver','sgd','KFold',5,'Lambda',lambdas);
        mse = kfoldLoss(lmcv);
        l = lambdas(find(mse==min(mse),1));

        %learn model on training set
        lm = fitrlinear(subset1,subdim1(:,i),'Regularization','lasso','Learner','leastsquares','Solver','sgd','Lambda',l);

        %predict dimensions
        Y = predict(lm,subset2);
        Y(Y<0) = 0; %positive
        dimP(1,:,i) = Y;

        Y = predict(lm,subset3);
        Y(Y<0) = 0; %positive
        dimP(2,:,i) = Y;

    end

    %train regression on Exp2 set, predict Exp1 matching set and second? set

    for i = 1:ndim2

        lmcv = fitrlinear(subset3,subdim3(:,i),'Regularization','lasso','Learner','leastsquares','Solver','sgd','KFold',5,'Lambda',lambdas);
        mse = kfoldLoss(lmcv);
        l = lambdas(find(mse==min(mse),1));

        lm = fitrlinear(subset3,subdim3(:,i),'Regularization','lasso','Learner','leastsquares','Solver','sgd','Lambda',l);

        Y = predict(lm,subset1); %matching subset
        Y(Y<0) = 0; %positive
        dimP(3,:,i) = Y;

    end

    %get correlations with original dimensions, allowing mappings to vary
    %in order and to repeat

    dimcorr = nan(3,ndim2);
    dimidx = nan(3,ndim2);

    %for Exp1-->
    for i = 1:ndim1

        c = NaN;

        for ii = 1:ndim1

            dimpred = squeeze(dimP(1,:,i));
            r = corr(dimpred',subdim2(:,ii));
            if isnan(c), c = r; d = ii; end
            if r>c, c = r; d = ii; end

        end

        dimcorr(1,i) = c;
        dimidx(1,i) = d;

        c = NaN;

        for ii = 1:ndim2

            dimpred = squeeze(dimP(2,:,i));
            r = corr(dimpred',subdim3(:,ii));
            if isnan(c), c = r; d = ii; end
            if r>c, c = r; d = ii; end

        end

        dimcorr(2,i) = c;
        dimidx(2,i) = d;
    end

    for i = 1:ndim2

        c = NaN;

        for ii = 1:ndim1

            dimpred = squeeze(dimP(3,:,i));
            r = corr(dimpred',subdim1(:,ii));
            if isnan(c), c = r; d = ii; end
            if r>c, c = r; d = ii; end

        end

        dimcorr(3,i) = c;
        dimidx(3,i) = d;

    end

    if featset==1
        feat.dimcorr = dimcorr;
        feat.dimidx = dimidx;
        feat.dimpred = dimP;
        save(savefile,'feat')
    else
        clip.dimcorr = dimcorr;
        clip.dimidx = dimidx;
        clip.dimpred = dimP;
        save(savefile,'-append','clip')
    end

    subplot(1,2,featset)
    boxplot_jitter_groups(dimcorr, {'1-1', '1-2', '2-1'}, [])

    nperm = 1000;
    randcorr = nan(nperm,3,ndim2); randidx = nan(nperm,nvid);
    for it = 1:nperm, randidx(it,:) = randperm(nvid); end
    
    dimP_orig = dimP; %save unshuffled predicted dimensions

    for it = 1:nperm

        dimP = dimP_orig(:,randidx(it,:),:);

        for i = 1:ndim1

            c = NaN;

            for ii = 1:ndim1

                dimpred = squeeze(dimP(1,:,i));
                r = corr(dimpred',subdim2(:,ii));
                if isnan(c), c = r; end
                if r>c, c = r; end

            end

            randcorr(it,1,i) = c;
            c = NaN;

            for ii = 1:ndim2

                dimpred = squeeze(dimP(2,:,i));
                r = corr(dimpred',subdim3(:,ii));
                if isnan(c), c = r; end
                if r>c, c = r; end

            end

            randcorr(it,2,i) = c;
        end

        for i = 1:ndim2

            c = NaN;

            for ii = 1:ndim1

                dimpred = squeeze(dimP(3,:,i));
                r = corr(dimpred',subdim1(:,ii));
                if isnan(c), c = r; end
                if r>c, c = r; end

            end

            randcorr(it,3,i) = c;

        end
    end

    randcorrmax = squeeze(max(nanmean(randcorr,3),[],2)); 

        if featset==1
            feat.randcorr = randcorr;
            feat.randcorrmax = randcorrmax;
            save(savefile,'-append','feat')
        else
            clip.randcorr = randcorr;
            clip.randcorrmax = randcorrmax;
            save(savefile,'-append','clip')
        end   

end


%% plot results
figure

cfg = [];
cfg.ylabel = 'Pearson''s r';
cfg.color = {[0.5 0.5 0.5], [0.5 0.5 0.8], [0.5 0.7 0.6]};
cfg.chance = feat.randcorrmax;
cfg.mrksize = 100;

subplot(1,2,1)
boxplot_jitter_groups(feat.dimcorr, {'Within Exp 1', 'Exp 1 - Exp 2', 'Exp 2 - Exp 1'}, cfg)
title('A','FontWeight','normal')
ylim([0 1])
yticks(0:0.2:1)

subplot(1,2,2)
cfg.ylabel = '';
cfg.chance = clip.randcorrmax;
boxplot_jitter_groups(clip.dimcorr, {'Within Exp 1', 'Exp 1 - Exp 2', 'Exp 2 - Exp 1'}, cfg)
title('B','FontWeight','normal')
ylim([0 1])
yticks(0:0.2:1)


