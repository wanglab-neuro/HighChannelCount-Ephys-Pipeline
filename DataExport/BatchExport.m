function [dataFiles,allRecInfo]=BatchExport(exportDir,overWrite,NWBexport)

if nargin<2; overWrite=true; end
if nargin<3; NWBexport=false; end

% Prepare the export directory
rootDir=cd;
if ~isfolder('SpikeSorting'); mkdir('SpikeSorting'); end % create export directory if needed
if ~exist('exportDir','var')
    exportDir=(fullfile(rootDir,'SpikeSorting'));
end

%% List data files
% Define recording file formats / folder to keep or exclude
fileFormats.keep={'*.dat','*raw.kwd','*RAW*Ch*.nex','*.ns*'};
fileFormats.exclude={'_export';'_TTLs'; '_trialTTLs';...
                     '_vSyncTTLs';'_actuators_TS';'temp_wh';...
                     '_nopp.dat';'_all_sc';'_VideoFrameTimes';'_Wheel'};
fileFolder.exclude={'_SC';'_JR';'_ML'};
% Same for video files
videoFormats.keep={'*.mp4','*.avi'};
videoFolder.exclude={'WhiskerTracking'}; %don't include WhiskerTracking folder

dataFiles = cellfun(@(fileFormat) dir([cd filesep '**' filesep fileFormat]),fileFormats.keep,'UniformOutput', false);
dataFiles=vertcat(dataFiles{~cellfun('isempty',dataFiles)});

% If Blackrock .ns files, check highest, then ignore others for now
fileF=cellfun(@(x) x(end-3:end), {dataFiles.name},'UniformOutput', false);
if any(cellfun(@(x) contains(x,'.ns'),fileF))
    nsIdx=find(cellfun(@(x) contains(x,'.ns'),fileF));
    if numel(unique(fileF(nsIdx)))>1
    keepFF=sort(string(cell2mat(unique(fileF(nsIdx))')),'descend');keepFF=keepFF(1);
    [sortFF,sortIdx]=sort(string(cell2mat(fileF(nsIdx)')),'descend');
    dataFiles=dataFiles(~ismember(1:numel(dataFiles),nsIdx(sortIdx(find(~contains(sortFF,keepFF),1):end))));
    end
end

% In case other export / spike sorting has been performed, do not include those files
dataFiles=dataFiles(~cellfun(@(flnm) contains(flnm,fileFormats.exclude),{dataFiles.name})); %by filename
dataFiles=dataFiles(~cellfun(@(flnm) contains(flnm,fileFolder.exclude),{dataFiles.folder})); % by folder name

%also check if there are video frame times to export
videoFiles = cellfun(@(fileFormat) dir([cd filesep '**' filesep fileFormat]),...
    videoFormats.keep,'UniformOutput', false);
videoFiles=vertcat(videoFiles{~cellfun('isempty',videoFiles)});
if ~isempty(videoFiles)
    videoFiles=videoFiles(~cellfun(@(flnm) contains(flnm,videoFolder.exclude),{videoFiles.folder})); 
end

% check if experiment notes' json file exists
parentList=dir('..');
notesIdx=cellfun(@(fName) contains(fName,'_notes.json'), {parentList.name});
if any(notesIdx)
    %get session notes
    notesFile=fullfile(parentList(notesIdx).folder,parentList(notesIdx).name);
    notes=jsondecode(fileread(notesFile));
else
    disp(['Subject notes not found in parent directory of ' regexp(cd,['(?<=\' filesep ')\w+$'],'match','once')]);
    notes=[];
end

allRecInfo=cell(size(dataFiles,1),1);

%% export each file
for fileNum=1:size(dataFiles,1)

    [recInfo,recordings,spikes,...
        videoTTL,trialTTL,laserTTL,fsData,reData] = LoadData(dataFiles(fileNum).name,dataFiles(fileNum).folder,notes);

    allRecInfo{fileNum}=recInfo;

    vSyncTTLDir=cd;
    
    %% fill in some info about the recording
    if ~isempty(notes) && any(contains({notes.Sessions.baseName},dataFiles(fileNum).name(1:end-4)))
        sessionIdx=contains({notes.Sessions.baseName}, dataFiles(fileNum).name(1:end-4));
        recInfo.baseName=notes.Sessions(sessionIdx).baseName;
        recInfo.subject=notes.Sessions(sessionIdx).subject;
        recInfo.shortDate=notes.Sessions(sessionIdx).shortDate;
        recInfo.probeDepth=notes.Sessions(sessionIdx).depth;
    else
        if contains(dataFiles(fileNum).name,'continuous')
            % in case they're called 'continuous' or some bland thing like this - basically, Open Ephys
            foldersList=regexp(strrep(dataFiles(fileNum).folder,'-','_'),...
                ['(?<=\' filesep ').+?(?=\' filesep ')'],'match');
            expNum=foldersList{cellfun(@(fl) contains(fl,'experiment'),foldersList)}(end);
            recNum=foldersList{cellfun(@(fl) contains(fl,'recording'),foldersList)}(end);
            recordingName=foldersList{find(cellfun(@(fl) contains(fl,'experiment'),foldersList))-1};
            recordingName=[recordingName '_' expNum '_' recNum];
        elseif contains(dataFiles(fileNum).name,'experiment')
            folderIdx=regexp(dataFiles(fileNum).folder,['(?<=\w\' filesep ').+?']);
            if isempty(folderIdx)
                folderIdx=1;
            end
            recordingName=strrep(dataFiles(fileNum).folder(folderIdx(end):end),'-','_');
        else
            recordingName=dataFiles(fileNum).name(1:end-4);
        end
        recInfo.baseName=recordingName;
        recNameComp=regexp(strrep(recordingName,'_','-'),'\w+','match');
        recInfo.subject=recNameComp{1};
        recInfo.shortDate=recNameComp{2};
        recInfo.probeDepth=recNameComp{3};
    end
    recInfo.dataPoints=int32(recInfo.dataPoints);

    %% get video sync TLLs
    if ~exist('videoTTL','var') && isempty(videoTTL)
        try % this should already be performed by LoadTTL, called from LoadEphysData above
            cd(vSyncTTLDir); dirListing=dir(vSyncTTLDir);
            % see LoadTTL - change function if needed
            if contains(dataFiles(fileNum).name, 'continuous.dat')
                cd(['..' filesep '..' filesep 'events' filesep 'Rhythm_FPGA-100.0' filesep 'TTL_1']);
                videoSyncTTLFileName='channel_states.npy';
            elseif contains(dataFiles(fileNum).name, 'raw.kwd')
                videoSyncTTLFileName=dirListing(cellfun(@(x) contains(x,'kwe'),...
                    {dirListing.name})).name;
            end
            frameCaptureTime=GetTTLFrameTime(videoSyncTTLFileName); %timestamps are actually sample count
            % convert to seconds dividing by sample rate
            %             cd(exportDir); cd (['..' filesep 'WhiskerTracking'])
            %         save([recordingName '_VideoFrameTimes'],'frameCaptureTime')
            %         continue;
            %             [recInfo,data,trials] = LoadEphysData(dataFiles(fileNum).name,dataFiles(fileNum).folder);
        catch
            %  if no vSyncTTL channel, then video sync was likely done with
            % flashing a LED. Need to first export TTLsync csv using Bonsai script.
            % Folder should then have two csv file for each video file:
            % Frame times and _TTLOnset
            videoFrameTimeFileName=dirListing(cellfun(@(fName) ...
                strcmp(regexprep(fName,'\d+\-\d+',''),[recordingName '_HSCam.csv']),...
                {dirListing.name})).name;
            if ~isempty(videoFrameTimeFileName)
                videoFrameTimes=ReadVideoFrameTimes(videoFrameTimeFileName);
                % synchronize based on trial structure
                try
                    vSyncDelay=mean(videoTTL.TTLtimes/videoTTL.samplingRate*1000-...
                        videoFrameTimes.frameTime_ms(videoFrameTimes.TTLFrames(...
                        [true;diff(videoFrameTimes.TTLFrames)>1]))');
                catch % different number of TTLs. Possibly "laser" sync. Assuming first 20 correct
                    videoIndexing=[true;diff(videoFrameTimes.TTLFrames)>1];
                    videoIndexing(max(find(videoIndexing,20))+1:end)=false;
                    vSyncDelay=mean(videoTTL.TTLtimes(1:20)/videoTTL.samplingRate*1000-...
                        videoFrameTimes.frameTime_ms(videoFrameTimes.TTLFrames(...
                        videoIndexing))');
                end
                % keep an array of timestamp (converted into sample count)
                % if video started before ephys recording (typical case)
                % then early times and thus frame count will be negative
                videoFrameTimes.frameTime_ms=videoFrameTimes.frameTime_ms+vSyncDelay;
                frameCaptureTime=int64(videoFrameTimes.frameTime_ms'*recInfo.samplingRate/1000);
                % second row keeps TTL pulse indices
                frameCaptureTime(2,:)=zeros(1,length(frameCaptureTime));
                frameCaptureTime(2,videoFrameTimes.TTLFrames)=1;
            else
                frameCaptureTime=[];
            end
        end
    end
    
    %% check that recordingName doesn't have special characters
    recordingName=regexprep(recInfo.baseName,'\W','');
    allRecInfo{fileNum}.baseName=recordingName;
    
    cd(exportDir)
    if ~isfolder(recordingName)
        %create export directory
        mkdir(recordingName);
    end
    cd(recordingName)
    recInfo.export.directory=fullfile(exportDir,recordingName);
    
    %% save ephys data
    if overWrite
        fileID = fopen([recordingName '_export.bin'],'w');
        fwrite(fileID,recordings,'int16');
        fclose(fileID);
        recInfo.export.binFile=[recordingName '_export.bin'];
        allRecInfo{fileNum}.ephysExportName=recInfo.export.binFile;
    end

    %% save other data
    if exist('fsData','var') && ~isempty(fsData)
        if ~isfolder(fullfile(dataFiles(fileNum).folder,'FlowSensor'))
            mkdir(fullfile(dataFiles(fileNum).folder,'FlowSensor'));
        end
        fileID = fopen(fullfile(dataFiles(fileNum).folder,'FlowSensor',[recordingName '_fs.bin']),'w');
        fwrite(fileID,fsData,'int16');
        fclose(fileID);
        recInfo.export.binFile=[recordingName '_fs.bin'];
    end
    if exist('reData','var') && ~isempty(reData)
        if ~isfolder(fullfile(dataFiles(fileNum).folder,'RotaryEncoder'))
            mkdir(fullfile(dataFiles(fileNum).folder,'RotaryEncoder'));
        end
        fileID = fopen(fullfile(dataFiles(fileNum).folder,'RotaryEncoder',[recordingName '_re.bin']),'w');
        fwrite(fileID,reData,'int16');
        fclose(fileID);
        recInfo.export.binFile=[recordingName '_re.bin'];
    end
    
    %% save spikes
    if ~isempty(spikes.clusters)
        save([recordingName '_spikes'],'-struct','spikes');
        recInfo.export.spikesFile=[recordingName '_spikes.mat'];
    end
    
    %% save photostim TTLs 
    if exist('laserTTL','var') && ~isempty(laserTTL) && ~isempty(laserTTL(1).start)
        % discard native sr timestamps and convert to seconds if needed
        if any(strcmp({laserTTL.timeBase},'s')) %any([laserTTL.samplingRate]==1)
            laserTTL=laserTTL(strcmp({laserTTL.timeBase},'s'));
        else
            laserTTL=laserTTL([laserTTL.samplingRate]==1000);
            % convert timebase to seconds
            laserTTL.start=single(laserTTL.start)/laserTTL.samplingRate;
            laserTTL.end=single(laserTTL.end)/laserTTL.samplingRate;
        end
        %swap dimensions if necessary
        if size(laserTTL.start,1)<size(laserTTL.start,2)
            laserTTL.start=laserTTL.start';
            laserTTL.end=laserTTL.end';
        end
        
        % save binary file
        fileID = fopen([recordingName '_optoTTLs.dat'],'w');
        fwrite(fileID,[laserTTL.start,laserTTL.end]','single'); %laserTTL.end'
        fclose(fileID);
        %save timestamps in seconds units as .csv
        writematrix([laserTTL.start,laserTTL.end],[recordingName '_optoTTLs.csv']); %,...
%             'delimiter', ','); % 'precision', '%5.4f'
        recInfo.export.TTLs={[recordingName '_optoTTLs.dat'];[recordingName '_optoTTLs.csv']}; %[recordingName '_export_trial.mat']};
    end
    
    %% or save trial TTLs (to be streamlined)
    if exist('trialTTL','var') && ~isempty(trialTTL) && ~isempty(trialTTL(1).start)
        %swap dimensions if necessary
        if size(trialTTL.start,1)<size(trialTTL.start,2)
            trialTTL.start=trialTTL.start';
            trialTTL.end=trialTTL.end';
        end
        
        % save binary file
        fileID = fopen([recordingName '_trialTTLs.dat'],'w');
        fwrite(fileID,[trialTTL.start,trialTTL.end]','single'); %trialTTL.end'
        fclose(fileID);
        %save timestamps in seconds units as .csv
        dlmwrite([recordingName '_trialTTLs.csv'],[trialTTL.start,trialTTL.end],...
            'delimiter', ',', 'precision', '%5.4f');
        recInfo.export.TTLs={[recordingName '_trialTTLs.dat'];[recordingName '_trialTTLs.csv']};
    end
    
    %% save video sync TTL data
    if exist('videoTTL','var') || (exist('frameCaptureTime','var') && ~isempty(frameCaptureTime))
        fileID = fopen([recordingName '_vSyncTTLs.dat'],'w');
        if exist('videoTTL','var') && isfield(videoTTL,'start') && ~isempty(videoTTL(1).start)
            %swap dimensions if necessary
            for i = 1:numel(videoTTL)
                videoTTL(i).start = shiftdim(videoTTL(i).start);
            end
            frameCaptureTime = videoTTL(end).start; % analog
            %             frameCaptureTime=[round(TTLtimes(1));round(TTLtimes(1))+cumsum(round(diff(TTLtimes)))]; %exact rounding
        elseif exist('videoTTL','var')
            frameCaptureTime = videoTTL;
        elseif exist('frameCaptureTime','var') && ~isempty(frameCaptureTime)
            % save video frame time file (vSync TTLs prefered method)
            frameCaptureTime = frameCaptureTime(1,frameCaptureTime(2,:)<0)';
            %             frameCaptureTime=[round(frameCaptureTime(1));round(frameCaptureTime(1))+cumsum(round(diff(frameCaptureTime)))];
        end
        fwrite(fileID,frameCaptureTime,'single'); %'int32' %just save one single column
        fclose(fileID);
        recInfo.export.vSync = [recordingName '_vSyncTTLs.dat'];
        copyfile([recordingName '_vSyncTTLs.dat'],fullfile(rootDir,[recordingName '_vSyncTTLs.dat']));
    end
    
    %% save actuator TTL data
    if exist('actuatorTTL','var') && ~isempty(actuatorTTL) && ~isempty(actuatorTTL(1).start)
        % discard native sr timestamps and convert to seconds if needed
        if any([actuatorTTL.samplingRate]==1)
            actuatorTTL=actuatorTTL([actuatorTTL.samplingRate]==1);
        else
            actuatorTTL=actuatorTTL([actuatorTTL.samplingRate]==1000);
            % convert timebase to seconds
            actuatorTTL.start=single(actuatorTTL.start)/actuatorTTL.samplingRate;
            actuatorTTL.end=single(actuatorTTL.end)/actuatorTTL.samplingRate;
        end
        %swap dimensions if necessary
        if size(actuatorTTL.start,1)<size(actuatorTTL.start,2)
            actuatorTTL.start=actuatorTTL.start';
            actuatorTTL.end=actuatorTTL.end';
        end
        
        % save binary file
        fileID = fopen([recordingName '_actuators_TS.dat'],'w');
        fwrite(fileID,[actuatorTTL.start';actuatorTTL.end'],'single'); %
        fclose(fileID);
        %save timestamps in seconds units as .csv (supersedes lasers if needed: rename as _trial.csv)
        dlmwrite([recordingName '_actuators_TS.csv'],[actuatorTTL.start;actuatorTTL.end]',...
            'delimiter', ',', 'precision', '%5.4f');
        recInfo.export.actuators_TS={[recordingName '_actuators_TS.dat'];...
            [recordingName '_actuators_TS.csv']}; %[recordingName '_export_trial.mat']};
    end
        
    %% save trial TTL data
    trials = struct('trialNum', [], 'start', [], 'stop', [], 'isphotostim', []);
    if exist('trialTTL','var')
        %
         for stimN=1:size(trialTTL,2)
            trials((stimN)*2-1).trialNum=(stimN)*2-2;
            if stimN ==1; trials((stimN)*2-1).start=0; else;...
                    trials((stimN)*2-1).start=trialTTL(stimN-1).end(end); end
            trials((stimN)*2-1).stop=trialTTL(stimN).start(1);
            trials((stimN)*2-1).isphotostim=false;
            trials((stimN)*2).trialNum=(stimN)*2-1;
            trials((stimN)*2).start=trialTTL(stimN).start(1);
            trials((stimN)*2).stop=trialTTL(stimN).end(end);
            trials((stimN)*2).isphotostim=false;
        end
    elseif exist('laserTTL','var') && ~isempty(laserTTL) && ~isempty(laserTTL.TTLtimes)
        % if there's no task but photostims, create no-stim / stim trials:
        for stimN=1:size(laserTTL,2)
            trials((stimN)*2-1).trialNum=(stimN)*2-2;
            if stimN ==1; trials((stimN)*2-1).start=0; else;...
                    trials((stimN)*2-1).start=laserTTL(stimN-1).end(end); end
            trials((stimN)*2-1).stop=laserTTL(stimN).start(1);
            trials((stimN)*2-1).isphotostim=false;
            trials((stimN)*2).trialNum=(stimN)*2-1;
            trials((stimN)*2).start=laserTTL(stimN).start(1);
            trials((stimN)*2).stop=laserTTL(stimN).end(end);
            trials((stimN)*2).isphotostim=true;
        end
        if laserTTL(end).end(end) < recInfo.duration_sec
            trials((stimN)*2+1).trialNum=(stimN)*2;
            trials((stimN)*2+1).start=laserTTL(stimN).end(end);
            trials((stimN)*2+1).stop=recInfo.duration_sec;
            trials((stimN)*2+1).isphotostim=false;
        end
    else
        trials.trialNum=0; trials.start=0; trials.stop=recInfo.duration_sec; trials.isphotostim = 0;
    end
    recInfo.trials=trials;

    %% try to find likely companion video file
    if ~isempty(videoFiles)
        fileComp=cellfun(@(vfileName) intersect(regexp(dataFiles(fileNum).name,'[a-zA-Z0-9]+','match'),...
            regexp(vfileName,'[a-zA-Z0-9]+','match'),'stable'), {videoFiles.name},'un',0);
        fileMatchIdx=cellfun(@numel,fileComp)==max(cellfun(@numel,fileComp));
        if any(fileMatchIdx)==1
            %likely match
            recInfo.likelyVideoFile=videoFiles(fileMatchIdx).name;
        end
    end
   
    %% save data info
    % save as .mat file (will be discontinued)
    save([recordingName '_recInfo'],'recInfo','-v7.3');
    
    % save a json file in the root folder for downstream pipeline ingest
    SaveSessionInfo(recInfo, recordingName, rootDir)

    % TBD: insert session info in pipeline right here
    if NWBexport
        FormatToNWB;
    end
    
end
cd ..


