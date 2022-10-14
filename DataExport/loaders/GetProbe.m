function [probeFileName,probePathName]=GetProbe(rootDir,notes,doCopy)

%% find / ask for probe file when exporting and copy to export folder
probeFile = cellfun(@(fileFormat) dir(fullfile(rootDir,'SpikeSorting', fileFormat)),...
    {'*.json'},'UniformOutput', false);

if ~isempty(probeFile{:})
    probeFileName=probeFile{1, 1}.name;
    probePathName=probeFile{1, 1}.folder;
else
    sessionsFolder=regexp(rootDir,['(?<=\' filesep ')\w+$'],'match','once');
    % locate probe files folder
    filePath  = mfilename('fullpath');
    filePath = regexp(filePath,['.+(?=\' filesep '.+$)'],'match','once'); %removes filename
    probePathName = fullfile(fileparts(filePath), 'probemaps');
    if isempty(notes)
        % check if info is in subject json file
        parentList=dir('..');
        notesIdx=cellfun(@(fName) contains(fName,'_notes.json'), {parentList.name});
        if any(notesIdx)
            %get session notes
            notesFile=fullfile(parentList(notesIdx).folder,parentList(notesIdx).name);
            notes=jsondecode(fileread(notesFile));
        end
    end
    if ~isempty(notes) && isfield(notes,'Sessions')
        % get probe info
        sessionIdx=contains({notes.Sessions.baseName}, sessionsFolder,'IgnoreCase',true);
        probe=notes.Sessions(find(sessionIdx,1)).probe;
        %load probe list
        probeList = fileread(fullfile(probePathName, 'probeList.json'));
        probeList = jsondecode(probeList);
        %find probe type
        probeTypeIdx=cellfun(@(probeID) contains(strrep(probe,' ',''),probeID),{probeList.probeLabel});
        probeType=probeList(probeTypeIdx).probeType;
        % find adapter type
        adapter=notes.Sessions(find(sessionIdx,1)).adapter;
        adapter=strrep(adapter,'Adapter','Adaptor');
        adapter=strrep(adapter,' ','');
        % combine
        probeFileName=[probeType '_' adapter '.json'];
    else
        %or ask
        [probeFileName,probePathName] = uigetfile('*.json',['Select the .json probe file for ' sessionsFolder],probePathName);
    end
    if doCopy
        copyfile(fullfile(probePathName,probeFileName),fullfile(cd,'SpikeSorting',probeFileName));
    end
end
