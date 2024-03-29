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
if nargin < 5; curateSort=false; end

[filepath,folderName] = fileparts(dataDir);

%% Export notes
if exportNotes
    % list directories above, assuming the parent folder is the container for
    % all files and data for that subject.
    parentDir=regexp(dataDir,['(?<=\' filesep ').+?(?=\' filesep ')'],'match');
    parentDir = parentDir{end};
    subjectNotes={['Experiment Note Sheet - ' parentDir '.xlsx'];[parentDir '.xlsx']};
    if exist(fullfile(filepath,subjectNotes{1}),'file')
        ExportXPNotes(subjectNotes{1}, filepath);
    elseif exist(fullfile(filepath,subjectNotes{2}),'file')
        ExportXPNotes(subjectNotes{2}, filepath);
    else
        disp('No subject notes found');
    end 
end

%% Export files with BatchExport
if exportData
    % start from data session's root directory
    cd(dataDir);
    [dataFiles,allRecInfo]=BatchExport;
    save('fileInfo','dataFiles','allRecInfo');
end

%%

%% Sort spikes
if spikeSort
    switch spikeSort
        case {true, 'KS'}
            BatchSpikeSort_KS(dataDir,folderName);
            if curateSort
                switch curateSort
                    case {true, 'JRC'}
                        ImportKStoJRC(dataDir);
                    otherwise
                end
            end
        case {'JRC'}
            BatchSpikeSort_JRC(dataDir,folderName);
        otherwise
            % may use other sorters, or compare results with SpikeInterface
    end
end



end