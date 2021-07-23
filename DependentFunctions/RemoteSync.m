function RemoteSync(fileName,outDirTemplate,originDir,exportName,syncType)

if nargin<5 || isempty(syncType)
    syncType='CopyAndSync_ToServer_Analysis';
end
if nargin<4 || isempty(exportName)
    exportName=fileName;
end
if nargin<3 || isempty(originDir)
    originDir = cd;     exportName=fileName;
end
% outDirTemplate=fullfile(directoryHierarchy{1:end-1},'Analysis',commonStr);
% conn=jsondecode(fileread(fullfile(fileparts(mfilename('fullpath')),'NESE_connection.json')));
conn=jsondecode(fileread(fullfile('V:\Code\Souris','NESE_connection.json')));

% fileName = allDataFiles.(adf_fn{dataFileNum}).name;
switch syncType
    case  'CopyAndSync_FromServer_Analysis' %strcmp(originDir(1),{'Z';'Y'})
        % files on server:     %     copyfile too slow on FSTP - use scp
        inDir=[replace(originDir,...
            originDir(1:3),...
            [conn.userName '@' conn.hostName ':' conn.labDir]) filesep];
        inDir=replace(inDir,'\','/');
        outDir=[replace(outDirTemplate,outDirTemplate(1:3),...
            'D:\') filesep];
        %     outDir=replace(outDir,'SpikeSorting','Analysis');
        [outDir,targetDir] = deal(replace(outDir,'Ephys\',''));
        if ~exist(outDir,'dir')
            mkdir(outDir);
        end
        
        command = ['scp ' inDir fileName ' ' outDir];
        % execute copy to target folder
        system(command);
        
        %% server copy with ssh
        inDir=[replace(originDir,...
            originDir(1:3),...
            conn.labDir) filesep];
        inDir=replace(inDir,'\','/');
        outDir=[replace(outDirTemplate,outDirTemplate(1:3),...
            conn.labDir) filesep];
        outDir=replace(outDir,'\','/');
        if ~exist(outDir,'dir')
            mkdir(outDir);
        end
        
        % created satori2 shortcut in .ssh/config file
        command = ['ssh satori2 "cp ' inDir fileName ' ' outDir fileName '"']; %mv is faster, if moving file is ok
        system(command);
        
    case 'CopyAndSync_ToServer_Analysis'
        %% file already on local computer
        % just copy it to target folder
        targetDir = outDirTemplate;
        copyfile(fullfile(originDir,...
            fileName),...
            fullfile(outDirTemplate,exportName));
        
        %% server side
        % upload a copy to target folder on server
        outDir=[replace(originDir,...
            originDir(1:3),...
            [conn.userName '@' conn.hostName ':' conn.labDir]) filesep];
        outDir=replace(outDir,'SpikeSorting','Analysis');
        outDir=replace(outDir,'Vincent','Vincent\Ephys');
        outDir=replace(outDir,'\','/');
        
        command = ['scp ' fileName ' ' outDir];
        system(command);
    case 'Sync_ToServer_SpikeSorting'
        % upload a copy to target folder on server
        outDir=[replace(originDir,...
            originDir(1:3),...
            [conn.userName '@' conn.hostName ':' conn.labDir]) filesep];
        outDir=replace(outDir,'Vincent','Vincent\Ephys');
        outDir=replace(outDir,'\','/');
        
        command = ['scp ' fullfile(originDir,fileName) ' ' outDir];
        system(command);
end
