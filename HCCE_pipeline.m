function HCCE_pipeline(exportNotes, exportData, spikeSort)
% Runs the blackrock pipline with analysis options of your choice.
%   exportNotes: boolean 
%   exportData: boolean
%   spikeSort: boolean
dataDir = cd;
[filepath,folderName] = fileparts(dataDir);


%% Export notes
%exportNotes = 0;
if exportNotes
    % list directories above, assuming the parent folder is the container for
    % all files from that subject
    parentDir=regexp(dataDir,['(?<=\' filesep ').+?(?=\' filesep ')'],'match');
    parentDir = parentDir{end};
    ExportXPNotes(['Experiment Note Sheet - ' parentDir '.xlsx'] , filepath)
end

%% Export .dat files with BatchExport
%exportData = 0;
if exportData
    % start from data session's root directory
    [dataFiles,allRecInfo]=BatchExport;
    save('fileInfo','dataFiles','allRecInfo');
end

%spikeSort = 1;
if spikeSort
    BatchSpikeSort_KS_JRC(dataDir,folderName,allRecInfo)
end


end