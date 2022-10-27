function [recInfo,varargout] = LoadData(fName,dName,notes)
nout = max(nargout,1) - 1;
varargout=cell(nout,1);
isRecSession=true;
if ~isempty(notes)
    % check if this is a recording session
    [~,mostCommonIdx]=sort(cellfun(@(bn) sum(ismember(fName,bn)), {notes.Sessions.baseName}),'descend');
    sessionProbe=notes.Sessions(mostCommonIdx(1)).probe;
    if isempty(sessionProbe)
        isRecSession=false; %no ephys recording (e.g., training)
    end
end

% Load ephys + TTL data
try
    [recInfo,recordings,spikes,TTLdata] = LoadEphysData(fName,dName);

    videoTTL=TTLdata(strcmp({TTLdata.channelType},'Camera'));
    trialTTL=TTLdata(strcmp({TTLdata.channelType},'Zaber'));
    laserTTL=TTLdata(strcmp({TTLdata.channelType},'Laser'));

    if isempty(recordings)
        isRecSession=false;
    end

    varargout{1}=recordings;
    varargout{2}=spikes;
    varargout{3}=videoTTL;
    varargout{4}=trialTTL;
    varargout{5}=laserTTL;

catch
    
end
   
if isRecSession
    GetProbe(dName,notes,isRecSession);
end

%% load other data
if contains(fName,{'.nev','.ns'})
    NEVdata=openNEV(fullfile(dName,[fName(1:end-3), 'nev']),'overwrite');
    if isfield(NEVdata.ElectrodesInfo,'ElectrodeLabel')
        fsIdx=cellfun(@(x) contains(x','FlowSensor'),{NEVdata.ElectrodesInfo.ElectrodeLabel});
        if any(fsIdx)
            try
                fsData = openNSx(fullfile(dataFiles(fileNum).folder,[dataFiles(fileNum).name(1:end-3), 'ns4']));
                fsIdx = cellfun(@(x) contains(x,'FlowSensor'),{fsData.ElectrodesInfo.Label});
                varargout{6} = fsData.Data(fsIdx,:);
            catch
            end
        end
        reIdx = cellfun(@(x) contains(x','RotaryEncoder'),{NEVdata.ElectrodesInfo.ElectrodeLabel});
        if any(reIdx)
            try
                reData = openNSx(fullfile(dataFiles(fileNum).folder,[dataFiles(fileNum).name(1:end-3), 'ns2']));
                reIdx = cellfun(@(x) contains(x,'RotaryEncoder'),{reData.ElectrodesInfo.Label});
                varargout{7} = reData.Data(reIdx,:);
            catch
            end
        end
    end
end