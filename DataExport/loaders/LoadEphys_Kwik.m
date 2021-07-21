function [data,rec]=LoadEphys_Kwik(dname,fname)
if contains(fname,'raw.kwd')
     %% Kwik format - raw data      
     
% The last number in file name from Open-Ephys recording is Node number
% e.g., experiment1_100.raw.kwd is "raw" recording from Node 100 for
% experiment #1 in that session.
% Full recording parameters can be recovered from settings.xml file.
% -<SIGNALCHAIN>
%     -<PROCESSOR NodeId="100" insertionPoint="1" name="Sources/Rhythm FPGA">
%         -<CHANNEL_INFO>
%             ...
%     -<CHANNEL name="0" number="0">
%         <SELECTIONSTATE audio="0" record="1" param="1"/>
%             ...
%   ...
%     -<PROCESSOR NodeId="105" insertionPoint="1" name="Filters/Bandpass Filter">
%         -<CHANNEL name="0" number="0">
%            <SELECTIONSTATE audio="0" record="1" param="1"/>
%                <PARAMETERS shouldFilter="1" lowcut="1" highcut="600"/>

%general info: h5disp(fname)
rawInfo=h5info(fname);%'/recordings/0/data'
rawInfo=h5info(fname,rawInfo.Groups.Name);
%   chanInfo=h5info([regexp(fname,'^[a-z]+1','match','once') '.kwx']);
%get basic info about recording
% if more than one recording, ask which to load
if size(rawInfo.Groups,1)>1
    recToLoad = inputdlg('Multiple recordings. Which one do you want to load?',...
        'Recording', 1);
    recToLoad = str2num(recToLoad{:});
else
    recToLoad =1;
end
rec.dur=rawInfo.Groups(recToLoad).Datasets.Dataspace.Size;
dirlisting = dir(dname);
rec.date=dirlisting(cell2mat(cellfun(@(x) contains(x,fname),{dirlisting(:).name},...
    'UniformOutput',false))).date;
rec.samplingRate=h5readatt(fname,rawInfo.Groups(recToLoad).Name,'sample_rate');
rec.bitResolution=0.195; %see Intan RHD2000 Series documentation
rec.bitDepth=h5readatt(fname,rawInfo.Groups(recToLoad).Name,'bit_depth');
%   rec.numSpikeChan= size(chanInfo.Groups.Groups,1); %number of channels with recored spikes

%     rec.numRecChan=rawInfo.Groups.Datasets.Dataspace.Size;
rec.numRecChan=rawInfo.Groups(recToLoad).Datasets.Dataspace.Size-3;  %number of raw data channels.
% Last 3 are headstage's AUX channels (e.g accelerometer)
%load data (only recording channels)
tic;
%     data=h5read(fname,'/recordings/0/data',[1 1],[1 rec.numRecChan(2)]);
data=h5read(fname,'/recordings/0/data',[1 1],[rec.numRecChan(1) Inf]);
disp(['took ' num2str(toc) ' seconds to load data']);
rec.sys='OpenEphys';
else 
     %% Kwik format - spikes   
    disp('Check out OE_proc_disp instead');
    return
end
    