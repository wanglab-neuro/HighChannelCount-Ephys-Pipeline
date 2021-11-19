function [convsdf, convrasters, convrastsem]=conv_raster(rasters,fsigma,causal,start,stop,normepochFR)
%raster averaging

switch nargin
    case 1
        fsigma=10;
        start=1;
        stop=size(rasters,2);
        meanFR=0;
        stdFR=1;
    case {2, 3}
        start=1;
        stop=size(rasters,2);
        meanFR=0;
        stdFR=1;
    case 5
        meanFR=0;
        stdFR=1;
    case 6
    %bin-sized calculation of mean and std
    bsl_bins=reshape(normepochFR,fsigma,length(normepochFR)/fsigma);
    meanFR=mean(nanmean(bsl_bins,2)); % should be the same as nanmean(normepochFR)
    stdFR=std(nanmean(bsl_bins,2)); % better std estimate, as std(normepochFR) just overestimates std
end

if ~exist('causal','var')
    causal=0;
end

% need to remove NaN-containing trials
rasters=rasters(~isnan(mean(rasters(:,fsigma*3+start:stop-3*fsigma),2)),:);
% allocating
convrasters=NaN(size(rasters,1),stop(1)-start(1)-fsigma*6+1);
% convrasters=NaN(size(rasters,1),stop-start+1); %when switching convolution shape to 'same'

% figure;
% hold on
for trial=1:size(rasters,1)
% 	trialnans=isnan(rasters(trial,fsigma*3+start:stop-3*fsigma));
    if numel(start)==1
        convrasters(trial,:)=fullgauss_filtconv(rasters(trial,start:stop),fsigma,causal).*1000;
    else
            convrasters(trial,:)=fullgauss_filtconv(rasters(trial,start(trial):stop(trial)),...
                fsigma,causal).*1000;
    end
%     convrasters(trial,trialnans)=NaN;
%     plot(convrasters(trial,:));
end

% some trials might still fall short
if find(isnan(convrasters))
    stillnantrials=find(isnan(mean(convrasters,2)));
    for nant=1:length(stillnantrials)
        convrasters(stillnantrials(nant),isnan(convrasters(stillnantrials(nant),:)))=...
            nanmean(convrasters(stillnantrials(nant),...
            find(isnan(convrasters(stillnantrials(nant),:)),1)-10:find(isnan(convrasters(stillnantrials(nant),:)),1)));
    end
end

% convrasters=convrasters(:,fsigma*3+1:end-3*fsigma); %6 sigma ksize

%baseline normalization
convrasters=(convrasters-meanFR)./stdFR;

%SEM
convrastsem=std(convrasters)/ sqrt(size(convrasters,1));
% convrastsem = convrastsem * 1.96; % 95% of the data will fall within 1.96 standard deviations of a normal distribution

convsdf=nanmean(convrasters);

% integral normalization
% convsdf=zscore(convsdf);

% figure; plot(convrasters,'k');

end