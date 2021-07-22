function [data,rec,TTLs]=LoadEphys_Continuous(dName,fName)
%% Open Ephys old format
wb = waitbar( 0, 'Reading Data File...' );

rec.dirName=dName;
rec.fileName=fName;

%list all .continuous data files
fileListing=dir(dname);
fileChNum=regexp({fileListing.name},'(?<=CH)\d+(?=.cont)','match');
trueFileCh=~cellfun('isempty',fileChNum);
fileListing=fileListing(trueFileCh);
[~,fileChOrder]=sort(cellfun(@(x) str2double(x{:}),fileChNum(trueFileCh)));
fileListing=fileListing(fileChOrder);
%     for chNum=1:size(fileListing,1)
[data(chNum,:), timestamps(chNum,:), recinfo(chNum)] = load_open_ephys_multi_data({fileListing.name});
%     end
%get basic info about recording
rec.dur=timestamps(1,end);
rec.clockTimes=recinfo(1).ts;
rec.samplingRate=recinfo(1).header.sampleRate;
rec.numRecChan=chNum;
rec.date=recinfo(1).header.date_created;
rec.sys='OpenEphys';

%% TTLs
waitbar( 0.5, wb, 'getting TTL times and structure');
% Open Ephys format
try
    TTLs=getOE_Trials('channel_states.npy');
catch
    % May be the old format
    TTLs=getOE_Trials('all_channels.events');
end

close(wb);