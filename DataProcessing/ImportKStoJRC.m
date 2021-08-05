function ImportKStoJRC(dataDir)

%% generate probe and meta files.
cd(fullfile(dataDir,'SpikeSorting'))
GenerateProbeMap_JRC;

%% import results into JRC
if ~exist('dataFiles','var'); load('fileInfo.mat'); end
for fileNum=1:size(dataFiles,1)
    try
        recInfo = allRecInfo{fileNum};
        cd([recInfo.recordingName])
        jrc('bootstrap',[recInfo.recordingName '_export.meta'],'-noconfirm','-advanced')
        jrc('import-ksort',fullfile(cd,'kilosort3'),false);
        cd ..
    catch
        continue
    end
end

