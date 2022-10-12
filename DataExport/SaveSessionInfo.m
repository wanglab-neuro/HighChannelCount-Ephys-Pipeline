function SaveSessionInfo(recInfo, recordingName, rootDir)
%% Saves a json file in the root folder, for downstream pipeline ingest
%% To read the file:
%     recInfo = fileread(fullfile(rootDir,[recordingName '_recInfo.json']));
%     recInfo = jsondecode(recInfo);

fid  = fopen(fullfile(rootDir,[recordingName '_info.json']),'w');
fprintf(fid,'{\r\n');

%% write session info
fldNames=fieldnames(recInfo);
for fldNum=1:numel(fldNames)
    str=jsonencode(recInfo.(fldNames{fldNum}));
    if contains(fldNames{fldNum},'export')
        str=regexprep(str,'(?<={)"','\r\n\t\t"');
        str=regexprep(str,'(?<=,)"','\r\n\t\t"');
    end
    fprintf(fid,['\t"' fldNames{fldNum} '": %s,'],str);
    %         if fldNum<numel(fldNames); fprintf(fid,','); end
    fprintf(fid,'\r\n');
end

%% get info about recording location, laser, etc from notes
ephys=struct('probe', [],'adapter', [],'AP', [], 'ML', [],'depth', [], 'theta', [], 'phi', []);
photoStim=struct('protocolNum', [], 'stimPower', [], 'stimFreq', [],...
    'pulseDur', [], 'stimDevice', [], 'trainLength', []);

notesFile=fullfile(regexp(rootDir,['.+(?=\' filesep '.+$)'],'match','once'),...
    [recInfo.subject  '_notes.json']);
if any(exist(notesFile,'file'))
    notes=jsondecode(fileread(notesFile));
    % get info about that session
    if isfield(notes,'Sessions')
        sessionIdx=strcmp({notes.Sessions.baseName}, recInfo.baseName);
        session=notes.Sessions(sessionIdx);
    else
        session=[];
    end
    % allocate data
    if ~isempty(session)
        ephys=session; ephys=rmfield(ephys,{'baseName','date','stimPower',...
            'stimFreq','pulseDur', 'stimDevice'});ephys=ephys(1);
        if ~isfield(ephys,'theta'); ephys.theta=[]; end
        if ~isfield(ephys,'phy'); ephys.phy=[]; end

        photoStim=session; photoStim=rmfield(photoStim,{'baseName','date',...
            'probe','adapter','AP', 'ML','depth'});
        for protocolNum=1:size(photoStim,2) % in case there are multiple stimulation protocols
            photoStim(protocolNum).protocolNum=protocolNum-1;
        end
    end
end

if ~isempty(ephys.probe)
    % determine adapter
    if contains(ephys.adapter,'NN')
        aptPrefix = 'NN_';
    elseif contains(ephys.adapter,'CN')
        aptPrefix = 'CNT_';
    end
    if contains(ephys.probe,'32')
        aptSuffix = 'A32OM32';
    elseif contains(ephys.probe,'16')
        switch aptPrefix
            case 'NN_'
                aptSuffix = 'A32OM32'; % there's also a 'A32OM16x2' but I don't used it
            case 'CNT_'
                if contains(ephys.adapter,'A16OM16') %if explicitly mentioned
                    aptSuffix = 'A16OM16';
                else
                    aptSuffix = 'A32OM32'; %most recordings actually done with that one, as the 16Ch HS is too fat to fit well next to the holder.
                end
        end
    else
        chNum = regexp(probeFileName,'\d+','match','once');
        aptSuffix = ['A' chNum 'OM' chNum];
    end
    ephys.adapter = [aptPrefix aptSuffix];

    % strip probe name to keep either id number or equivalent
    ephys.probe=ephys.probe(1:regexp(ephys.probe,'(?=\d )\w+','once'));
    ephys.probe=strrep(ephys.probe,' ','');
end

% update with available real data
if exist('laserTTL','var') && ~isempty(laserTTL)
    for protocolNum=1:size(laserTTL,2)
        photoStim(protocolNum).pulseDur=mode(round(diff([laserTTL(protocolNum).start';...
            laserTTL(protocolNum).end']),4));
        photoStim(protocolNum).stimFreq=1/(mode(round(diff(laserTTL(protocolNum).start),4)));
        photoStim(protocolNum).trainLength=numel([laserTTL(protocolNum).start]);%'pulses_per_train'

        %% add photostim location info if available
        % stimulation can be through either:
        % 1/ an FO implant
        % 2/ FO on the probe
        % 3/ external (e.g., whisker pad)
        implantProc=cellfun(@(proc) contains(proc.Procedure,'FO'), notes.Procedures);
        %if comment is empty, use default order
        if isempty(str2num(photoStim(protocolNum).comments))
            if any(implantProc)
                photoStim.comments = 'implant';
            elseif contains(ephys.probe,{'Probe35','Probe36','FO'})
                photoStim.comments = 'probe';
            else %should ask
                photoStim.comments = 'external';
            end
        end
        switch photoStim(protocolNum).comments
            case 'implant'
                implantNotes=notes.Procedures{implantProc}.ExtendedNotes;
                photoStim.photostim_location=struct(...
                    'skullRef','Bregma',...
                    'ap_location',implantNotes.APcoord,...
                    'ml_location',implantNotes.MLcoord,...
                    'depth',implantNotes.Depth,...
                    'theta',str2num(regexp(implantNotes.Notes,'(?<= )\d+(?=d )','match','once')),...
                    'phi',0,...
                    'targetBrainArea',[]);
            case 'probe'
                photoStim.photostim_location=struct(...
                    'skullRef','Bregma',...
                    'ap_location',ephys.AP,...
                    'ml_location',ephys.ML,...
                    'depth',ephys.depth,...
                    'theta',ephys.theta,...
                    'phi',ephys.phy,...
                    'targetBrainArea',[]);
            case 'external'
                % not in the brain
        end
    end
elseif exist('laserTTL','var') && isempty(laserTTL)
    photoStim.trainLength=[];
    photoStim.protocolNum=-1;
end
str=strrep(jsonencode(ephys),',"',sprintf(',\r\n\t\t"'));
str=regexprep(str,'(?<={)"','\r\n\t\t"');
fprintf(fid,'\t"ephys": %s,\r\n',str);
str=strrep(jsonencode(photoStim),',"',sprintf(',\r\n\t\t"'));
str=regexprep(str,'(?<={)"','\r\n\t\t"');
fprintf(fid,'\t"photoStim": %s,\r\n',str);

%% add trial data

str=strrep(jsonencode(recInfo.trials),',"',sprintf(',\r\n\t\t"'));
str=regexprep(str,'(?<={)"','\r\n\t\t"');
str=regexprep(str,'},{','},\r\n\t\t{');
fprintf(fid,'\t"trials": %s\r\n',str);

% close file
fprintf(fid,'}');
fclose(fid);
