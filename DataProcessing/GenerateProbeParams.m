function probeParams=GenerateProbeParams(probeParams,recInfo)
remapped=false; %legacy variable

if ~isstruct(probeParams)
    if ischar(probeParams)
        probeParams.probeFileName=probeParams;
    elseif isfield(recInfo,'probeFileName')
        probeParams.probeFileName=recInfo.probeFileName;
    end
else
    if contains(probeParams.probeFileName,'Probe')  %non generic probe
        probeParams.probeFileName=replace(regexp(probeParams.probeFileName,'\w+(?=Probe)','match','once'),'_','');
    end
end

if isfield(recInfo.probeLayout,'description'); probeParams.description=recInfo.probeLayout.description; end
if isfield(recInfo.probeLayout,'manufacturer'); probeParams.manufacturer=recInfo.probeLayout.manufacturer; end
if isfield(recInfo.probeLayout,'adaptor'); probeParams.adaptor=recInfo.probeLayout.adaptor; end

probeParams.numChannels=numel({recInfo.probeLayout.Electrode}); %or check recInfo.signals.channelInfo.channelName %number of channels

if isfield(recInfo.probeLayout,'surfaceDim')
    probeParams.pads=recInfo.probeLayout.surfaceDim;
end
if isfield(recInfo.probeLayout,'maxSite')
    probeParams.maxSite=recInfo.probeLayout.maxSite;
end
% Channel map
if remapped==true
    probeParams.chanMap=1:probeParams.numChannels;
else
    switch recInfo.sys
        case 'OpenEphys'
            probeParams.chanMap={recInfo.probeLayout.OEChannel};
        case 'Blackrock'
            probeParams.chanMap={recInfo.probeLayout.BlackrockChannel};
    end
    % check for unconnected / bad channels
    if isfield(recInfo.probeLayout,'connected')
        probeParams.connected=logical(recInfo.probeLayout.connected);
        probeParams.chanMap=probeParams.chanMap{:}(probeParams.connected);
    else
        probeParams.connected=~cellfun(@isempty, probeParams.chanMap);
        probeParams.chanMap=[probeParams.chanMap{:}];
    end
end
probeParams.shanks=[recInfo.probeLayout.Shank];
probeParams.shanks=probeParams.shanks(probeParams.connected);
% probeParams.shanks=probeParams.shanks(~isnan([recInfo.probeLayout.Shank]));

%now adjust
probeParams.numChannels=sum(probeParams.connected);
probeParams.connected=logical(probeParams.chanMap);

if max(probeParams.chanMap)>probeParams.numChannels
    if  numel(probeParams.chanMap)==probeParams.numChannels
        %fine, just need adjusting channel numbers
        [~,probeParams.chanMap]=sort(probeParams.chanMap);
        [~,probeParams.chanMap]=sort(probeParams.chanMap);
    else
        disp('There''s an issue with the channel map')
    end
end

%geometry:
%         Location of each site in micrometers. The first column corresponds
%         to the width dimension and the second column corresponds to the depth
%         dimension (parallel to the probe shank).


if isfield(recInfo.probeLayout,'geometry')
    probeParams.geometry=recInfo.probeLayout.geometry;
else
    if isfield(recInfo.probeLayout,'x_geom')
        xcoords=[recInfo.probeLayout.x_geom];
        ycoords=[recInfo.probeLayout.y_geom];
    else
        xcoords = zeros(1,probeParams.numChannels);
        ycoords = 200 * ones(1,probeParams.numChannels);
        groups=unique(probeParams.shanks);
        for elGroup=1:length(groups)
            if isnan(groups(elGroup)) || groups(elGroup)==0
                continue;
            end
            groupIdx=find(probeParams.shanks==groups(elGroup));
            xcoords(groupIdx(2:2:end))=20;
            xcoords(groupIdx)=xcoords(groupIdx)+(0:length(groupIdx)-1);
            ycoords(groupIdx)=...
                ycoords(groupIdx)*(elGroup-1);
            ycoords(groupIdx(round(end/2)+1:end))=...
                ycoords(groupIdx(round(end/2)+1:end))+20;
        end
    end
    probeParams.geometry=[xcoords;ycoords]';
end
