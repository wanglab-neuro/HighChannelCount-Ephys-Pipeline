sessNum=2;

%% Set up the NWB file with general information
sessionInfo.description = notes.Sessions(sessNum).description;
sessionInfo.identifier = notes.Sessions(sessNum).baseName;
sessionInfo.session_start_time = datetime(recInfo.date,'Format','yyyy,MM,d,HH,mm,ss');
sessionInfo.experimenter=notes.Dataset.Experimenter;
sessionInfo.institution=notes.Dataset.Institution;

%% Subject information
subjectInfo.subjectID=notes.Header.SubjectID;
if ~isempty(notes.Header.DOB)
    subjectInfo.age=['P' upper(char(caldiff([datetime(notes.Header.DOB);...
        datetime(notes.Sessions(sessNum).fullDate)],'D')))];
else
    subjectInfo.age='P999D';
end
subjectInfo.description= ['Cagecard ' notes.Header.Cagecard ' Tag ' notes.Header.Tag];
subjectInfo.species='Mus musculus';
subjectInfo.strain=notes.Header.Type;
subjectInfo.genotype='';
subjectInfo.sex=notes.Header.Sex;
subjectInfo.weight='';

nwb=SaveToNWB(struct('sessionInfo',sessionInfo,'subjectInfo',subjectInfo));

%% Ephys %%
if ~isempty(notes.Sessions(sessNum).probe)
    %% Describe electrodes
    probeLayout = fileread(fullfile(recInfo.probePathName,recInfo.probeFileName));
    recInfo.probeLayout = jsondecode(probeLayout);
    [~,probeParams.probeFileName]=fileparts(recInfo.probeFileName);
    probeParams=GenerateProbeParams(probeParams,recInfo);
    probeParams.nshanks = numel(unique(probeParams.shanks));
end

%% Store "raw" voltage data
if exist('recordings',"var")
    recData.starting_time=0.0; % seconds
    recData.starting_time_rate=recInfo.samplingRate; % Sampling rate (Hz)
    recData.data=double(recordings(probeParams.chanMap,:))*recInfo.bitResolution;
    recData.electrodes=electrode_table_region;
    recData.data_unit='volts';
end

%% Store LFP data
if exist('LFP_data',"var")
    LFPData.starting_time=0.0; % seconds
    LFPData.starting_time_rate=1000; % Sampling rate (Hz)
    LFPData.data=LFP_data;
    LFPData.electrodes=electrode_table_region;
    LFPData.data_unit='volts';
end

%% Store spike data
if exist('spikes',"var")
    % Saving only spike times for now
    nwb=NWB_Ephys_Spikes(nwb, spikes.spikeTimes);
end

%%%%%%%%%%%%%%
%% Behavior %%
%%%%%%%%%%%%%%

%% Store continuous spatial data
if exist('spatialData',"var")
    spatialBehav.description='';            % e.g., 'Postion (x, y) in an open field.'
    spatialBehav.data=spatialData;
    spatialBehav.timestamps=timestamps;
    spatialBehav.reference_frame='';        % e.g., '(0,0) is the bottom left corner.'
    spatialData.dataType='';                % "Heading" "Eye" or "Position"

    nwb=NWB_Behavior_SpatialSeries(nwb, spatialData);
end

%% Store other continuous behavior data
clearvars continuousBehav
if exist('fsData',"var") && ~isempty(fsData)
    continuousBehav.description='breathing data from the flow sensor';         % e.g., 'running speed, computed from the rotary encoder'
    continuousBehav.data=fsData;                % e.g., rotary encoder data
    continuousBehav.starting_time_rate=10.0;    % Sampling rate (Hz)
    continuousBehav.data_unit='au_flow/s';      % e.g., 'm/s'
    continuousBehav.dataType='breathing';       % e.g., "breathing"

    nwb=NWB_Behavior_TimesSeries(nwb, continuousBehav);
end
if exist('reData',"var") && ~isempty(reData)
    continuousBehav.description='running data from the rotary encoder';         % e.g., 'running speed, computed from the rotary encoder'
    continuousBehav.data=reData;                % e.g., rotary encoder data
    continuousBehav.starting_time_rate=1.0;     % Sampling rate (Hz)
    continuousBehav.data_unit='m/s';            % e.g., 'm/s'
    continuousBehav.dataType='running';       % e.g., "breathing"

    nwb=NWB_Behavior_TimesSeries(nwb, continuousBehav);
end

%% Store behavioral events
if exist('eventData',"var") && ~isempty(reData)
    eventBehav.description='';          % e.g., 'The water amount the subject received as a reward'
    eventBehav.data=eventData;          % e.g., reward_amount
    eventBehav.timestamps=eventTS;      % e.g., event_timestamps
    eventBehav.data_unit='';            % e.g., 'ml'
    eventBehav.dataType='';             % e.g., 'lever_presses'

    nwb=NWB_Behavior_Events(nwb, eventBehav);
end

%% TTLs
TTLsVarList={'videoTTL','laserTTL','trialTTL'};
if any(contains(TTLsVarList,who))
        TTLvarIdx=find(contains(TTLsVarList,who));
        [TTLts,TTLdata]=deal(cell(numel(TTLvarIdx),1));
        TTLlabels=cell(numel(TTLvarIdx),1);
        for varNum=1:numel(TTLvarIdx)
            switch TTLsVarList{TTLvarIdx(varNum)}
                case 'videoTTL'
                    if ~isempty(videoTTL)
                    TTLts{varNum}=videoTTL.start;
                    TTLdata{varNum}=ones(numel(videoTTL.start),1);
                    TTLlabels{varNum}='videoTTL';
                    end
                case 'laserTTL'
                    if ~isempty(laserTTL)
                    TTLts{varNum}=laserTTL.start;
                    TTLdata{varNum}=2*ones(numel(laserTTL.start),1);
                    TTLlabels{varNum}='laserTTL';
                    end
                case 'trialTTL'
                    if ~isempty(trialTTL)
                    TTLts{varNum}=trialTTL.start;
                    TTLdata{varNum}=3*ones(numel(videoTTL.start),1);
                    TTLlabels{varNum}='trialTTL';
                    end
            end
        end
        TTLts=vertcat(TTLts{:}); [TTLts,sortIdx]=sort(TTLts);
        TTLdata=vertcat(TTLdata{:}); TTLdata=TTLdata(sortIdx);
        TTLlabels=horzcat(TTLlabels{:});

        TTLs.description='TTLs';       % 'TTLs for ...'
        TTLs.timestamps=TTLts   ;    % [0, 0.5, 0.6, 2, 2.05, 3, 3.5, 3.6, 4]
        TTLs.resolution=1/30e3 ;      % resolution of the timestamps, i.e., smallest possible difference between timestamps
        TTLs.data=TTLdata;             % [0, 1, 2, 3, 5, 0, 1, 2, 4]
        TTLs.labels=TTLlabels;        % ['camera1', 'camera1', 'camera1', 'laser', 'camera1', 'laser']
        TTLs.data_unit = 'seconds';

    nwb=NWB_TTLs(nwb, TTLs);
end

%% Video-based behavior tracking
% https://nwb-schema.readthedocs.io/en/latest/format_description.html#extending-timeseries-and-nwbcontainer
% For pose estimation, see also https://github.com/rly/ndx-pose

%%%%%%%%%%%%%%%%%%%%%
%% Trials / Epochs %%
%%%%%%%%%%%%%%%%%%%%%
% Trials can be stored in a TimeIntervals, BehavioralEpochs or IntervalSeries objects.
% Using TimeIntervals to represent time intervals is often preferred over
% BehavioralEpochs and IntervalSeries. TimeIntervals is a subclass of DynamicTable,
% which offers flexibility for tabular data by allowing the addition of
% optional columns which are not defined in the standard.

%% TimeIntervals
intervalData.description = ''; % e.g., 'Intervals when the animal was sleeping'
intervalData.colnames = ''; % e.g.,  {'start_time', 'stop_time', 'stage'}
intervalData.data = {}; % e.g., {[0.1, 1.5, 2.5];[1.0, 2.0, 3.0];[false, true, false]};
intervalData.dataType = ''; % e.g., 'sleep_intervals'

nwb=NWB_TimeIntervals(nwb, intervalData);

%% BehavioralEpochs
intervalData.description = ''; % e.g., 'Intervals when the animal was running'
intervalData.data = []; % e.g., [1, -1, 1, -1, 1, -1]; % IntervalSeries uses 1 to indicate the beginning of an interval and -1 to indicate the end.
intervalData.timestamps = ''; % e.g.,  [0.5, 1.5, 3.5, 4.0, 7.0, 7.3] in seconds
intervalData.dataType = ''; % e.g., 'running'

nwb=NWB_Behavior_Epochs(nwb, intervalData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Write data to a NWB file %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nwbExport(nwb, 'mydata.nwb');
