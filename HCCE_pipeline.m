function HCCE_pipeline(dataDir, exportNotes, exportData, spikeSort)
% Runs the high channel count ephys pipeline with analysis options of your choice.
%   dataDir: the directory where the data are 
%   exportNotes: boolean
%   exportData: boolean
%   spikeSort: boolean

if nargin == 0, dataDir = cd; end
if nargin < 2; exportNotes=false; end
if nargin < 3; exportData=true; end
if nargin < 4; spikeSort=true; end

%% Export notes
if exportNotes
    % list directories above, assuming the parent folder is the container for
    % all files from that subject
    parentDir=regexp(dataDir,['(?<=\' filesep ').+?(?=\' filesep ')'],'match');
    parentDir = parentDir{end};
    ExportXPNotes(['Experiment Note Sheet - ' parentDir '.xlsx'] , filepath)
end

%% Export files with BatchExport
if exportData
    % start from data session's root directory
    cd(dataDir);
    [dataFiles,allRecInfo]=BatchExport;
    save('fileInfo','dataFiles','allRecInfo');
end

%% Sort spikes
if spikeSort
    [~,folderName] = fileparts(dataDir);
    switch spikeSort
        case {true, 'KS'}
            BatchSpikeSort_KS_JRC(dataDir,folderName,allRecInfo)
        otherwise
            % may use other sorters, or compare results with SpikeInterface
    end
end


end