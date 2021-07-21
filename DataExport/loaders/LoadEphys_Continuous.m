function [data,rec]=LoadEphys_Continuous(dname)
%% Open Ephys old format  

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