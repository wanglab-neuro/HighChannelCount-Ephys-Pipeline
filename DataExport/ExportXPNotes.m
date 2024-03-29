function ExportXPNotes(fileName, fileDir)
if ~exist('fileDir','var')
    fileDir=cd;
end
if ~exist('fileName','var')
    fileList=dir(fileDir);
    fileName=fileList(cellfun(@(fName) contains(fName,'Experiment Note Sheet') &&...
        ~contains(fName,'old format'),...
        {fileList.name})).name;
end

%% Convert notes spreadsheet to json file

%% First read header
opts = spreadsheetImportOptions("NumVariables", 11);
opts.DataRange = "A2:K2";
opts.VariableNames = ["SubjectID", "VarName2", "VarName3", "VarName4", "VarName5", "Goal", "Type", "Sex", "DOB", "Tag", "Cagecard"];
opts.VariableTypes = ["char", "double", "double", "double", "double", "char", "char", "char", "datetime", "categorical", "double"];
opts.MissingRule = "omitvar";
opts = setvaropts(opts, ["SubjectID", "Goal", "Type", "Sex"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["SubjectID", "Goal", "Type", "Sex", "Tag"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, ["VarName2", "VarName3", "Cagecard", "DOB"], "TreatAsMissing", '');
opts = setvaropts(opts, "DOB", "InputFormat", "MM/dd/uu");

% Import data
xpNotesHeader = readtable(fullfile(fileDir, fileName), opts, "UseExcel", false);
if ~isfield(xpNotesHeader,'Cagecard'); xpNotesHeader.Cagecard=NaN; end
if ~isfield(xpNotesHeader,'DOB'); xpNotesHeader.DOB=NaN; end
clear opts

%% Now read experiment notes
opts = spreadsheetImportOptions("NumVariables", 10);
opts.DataRange = 5; % Starting at row 5
opts.VariableNames = ["Procedure", "Date", "APcoord", "MLcoord", "Depth", "Notes", "StimPower", "StimFreq", "PulseDur", "Device", "Comments"];
opts.VariableTypes = ["categorical", "datetime", "double", "double", "double", "string", "double", "double", "double", "categorical", "string"];
opts = setvaropts(opts, ["Notes", "Comments"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Procedure", "Notes", "Device", "Comments"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "Date", "InputFormat", "MM/dd/uu");

% Import  data
xpNotes = readtable(fullfile(fileDir, fileName), opts, "UseExcel", false);

% Note on coordinates:
% AP: anterior is positive
% ML: right is positive
% DV: dorsal is positive (add - to notes)

%% Write notes to json file
% adjust variables
xpNotesHeader.Cagecard=num2str(xpNotesHeader.Cagecard);
if xpNotesHeader.DOB < '01-Jan-2015'; xpNotesHeader.DOB(1)=''; end
if nanmean(xpNotes.Depth)>0; xpNotes.Depth=-xpNotes.Depth; end

%% find procedures and sessions (+ conditions within sessions, if any)
procedureIdx=~isundefined(xpNotes.Procedure);
sessionIdx=xpNotes.Procedure=='R'; % Ephys recordings should be noted as R
conditionIdx=xpNotes.Procedure=='C'; % Conditions within recordings should be noted as C
procedureIdx=find(procedureIdx & ~sessionIdx & ~conditionIdx);
sessionIdx=find(sessionIdx);
if ~isempty(sessionIdx)
    sessions=struct('subject',[],'shortDate',[],'fullDate',[],'description',[],'shortNotes',[],...
        'baseName',[],'probe',[],'adapter',[],'AP',[],'ML',[],'depth',[],...
        'stimPower',[],'stimFreq',[],'pulseDur',[],'stimDevice',[],'comments',[]);
end

%% check if project notes' json file exists
parentList=dir(fileparts(fileDir));
notesIdx=cellfun(@(fName) contains(fName,'project.json'), {parentList.name});
if any(notesIdx)
    %get project notes
    notesFile=fullfile(parentList(notesIdx).folder,parentList(notesIdx).name);
    notes=jsondecode(fileread(notesFile));
else
    disp(['Project notes not found in parent directory of ' fileparts(fileDir)]);
    notes=struct('Project',[],'Experimenter',[],'Institution',[],'Rig',[]);
end

%% open file
fid  = fopen(fullfile(fileDir,[char(xpNotesHeader.SubjectID) '_notes.json']),'w');
fprintf(fid,'{\r\n');

%% 1. Print project info 
fprintf(fid,'\t"Dataset": {\r\n');
str=strrep(jsonencode(notes),',"',sprintf(',\r\n\t\t"'));
str=strrep(str,'},{',sprintf('\r\n\t\t},\r\n\t\t{'));
fprintf(fid,'%s%s%s',sprintf('\t\t'), str(2:end-1), sprintf('\r\n\t},\r\n'));

%% 2. Print header variables
fprintf(fid,'\t"Header": {\r\n');
str=strrep(jsonencode(xpNotesHeader),',"',sprintf(',\r\n\t\t"'));
fprintf(fid,'%s%s%s',sprintf('\t\t'), str(3:end-2), sprintf('\r\n\t},\r\n'));

%% 3. Print notes
procedureRange=[];
fprintf(fid,'\t"Procedures": [\r\n');
for procNum=1:numel(procedureIdx)
    if any(ismember(procedureRange,procedureIdx(procNum)))
        continue
    end
    % find row range of procedure
    % Special procedures for injections and fiber optic implantation
    if ismember(xpNotes.Procedure(procedureIdx(procNum)),{'injection','implant FO'})
        specProcIdx=procedureIdx(...
            ~contains(string(xpNotes.Procedure(procedureIdx)),{'injection','fiber optic'}));
        procedureRange=procedureIdx(procNum):...
            specProcIdx(find(specProcIdx>procedureIdx(procNum),1))-1;
    else
        if procNum<numel(procedureIdx)
            procedureRange=procedureIdx(procNum):procedureIdx(procNum+1)-1;
        else
            procedureRange=procedureIdx(procNum):numel(xpNotes.Procedure);
        end
    end
    % print procedure type, date and head comment
    procedureInfo=strrep(jsonencode(xpNotes(procedureIdx(procNum),[1,2,6])),',"',sprintf(',\r\n\t\t"'));
    fprintf(fid,'\t\t%s',procedureInfo(2:end-2));
    
    % if there are other notes, add them
    if numel(procedureRange)>1
        % There are notes associated with the procedure.
        %% Three cases:
        %%   1/ any procedure listed above, excluding recordings
        if any(ismember(procedureIdx,procedureRange(2:end)))
            fprintf(fid,',\r\n\t\t"Subprocedures": [\r\n');
            subprocIdx=procedureIdx(ismember(procedureIdx,procedureRange(2:end)));
            for subprocNum=1:numel(subprocIdx)
                subprocedureInfo=strrep(jsonencode(xpNotes(subprocIdx(subprocNum),...
                    [1,3:6])),',"',sprintf(',\r\n\t\t\t\t"'));
                fprintf(fid,'\t\t\t\t%s',subprocedureInfo(2:end-2));
                
                if subprocNum<numel(subprocIdx)
                    subprocRange=subprocIdx(subprocNum+1)-1;
                else
                    subprocRange=procedureIdx(find(procedureIdx>subprocIdx(end),1))-1;
                end
                
                notes=xpNotes.Notes(subprocIdx(subprocNum)+1:subprocRange);
                notes=[notes{:}];
                if ~isempty(notes)
                    if any(regexp(notes,' '))
                        notes{1}(regexp(notes,' '))=' '; %remove special "thin space" (non-ASCII character)
                    end
                    fprintf(fid,',\r\n\t\t\t\t"Extended Notes": "%s"',notes);
                end
                fprintf(fid,'\r\n\t\t\t\t}');
                if subprocNum<numel(subprocIdx); fprintf(fid,',\r\n'); end
            end
            fprintf(fid,'\r\n\t\t\t]\r\n');
            
            %%   2/ * recordings (aka sessions in the pipeline, that groups
            %%       ephys, video and other concurrent recordings together)
            %%      * some procedures that do not have a stereotax coordinates
        elseif any(ismember(sessionIdx, procedureRange(2:end))) || contains(char(xpNotes.Procedure(procedureIdx(procNum))),'headpost')
            recMark=xpNotes.Procedure(procedureRange(2:end));
            recMark(isundefined(recMark))=('-'); recMark=string(recMark);
            depth=xpNotes.Depth(procedureRange(2:end));
            depthstr=string(depth); depthstr(isnan(depth))='    ';
            notes=xpNotes.Notes(procedureRange(2:end));
            for lineNum=1:size(notes,1)
                if any(regexp(notes(lineNum,:),'[\r\n]'))
                    notes(lineNum,:)=regexprep(notes(lineNum,:),'[\r\n]','",\r\t\t\t"-\t":\t"');
                end
            end
            % join notes
            notes=strjoin(recMark + sprintf('\t') + depthstr + sprintf(""":\t""") + notes,...
                '",\r\n\t\t\t"'); %[notes{:}];
            if any(regexp(notes,' '))
                notes{1}(regexp(notes,' '))=' '; %remove special "thin space" (non-ASCII character)
            end
            fprintf(fid,',\r\n\t\t"Extended Notes":{\r\n\t\t\t"%s"}\r\n',notes);
            
            %%   3/ Special case like FO implantation
        else
            fprintf(fid,',\r\n\t\t"Extended Notes": [\r\n');
            subprocIdx=procedureRange(2:end);
            for subprocNum=1:numel(subprocIdx)
                if isundefined(xpNotes.Procedure(subprocIdx(subprocNum)))
                    xpNotes.Procedure(subprocIdx(subprocNum)) = xpNotes.Procedure(procedureIdx(procNum));
                end
                subprocedureInfo=strrep(jsonencode(xpNotes(subprocIdx(subprocNum),...
                    [1,3:6])),',"',sprintf(',\r\n\t\t\t\t"'));
                fprintf(fid,'\t\t\t\t%s',subprocedureInfo(2:end-2));
                
                if subprocNum<numel(subprocIdx)
                    subprocRange=subprocIdx(subprocNum+1)-1;
                else
                    subprocRange=procedureIdx(find(procedureIdx>subprocIdx(end),1))-1;
                end
                
                notes=xpNotes.Notes(subprocIdx(subprocNum)+1:subprocRange);
                notes=[notes{:}];
                if ~isempty(notes)
                    if any(regexp(notes,' '))
                        notes{1}(regexp(notes,' '))=' '; %remove special "thin space" (non-ASCII character)
                    end
                    fprintf(fid,',\r\n\t\t\t\t"Extended Notes": "%s"',notes);
                end
                fprintf(fid,'\r\n\t\t\t\t}');
                if subprocNum<numel(subprocIdx); fprintf(fid,',\r\n'); end
            end
            fprintf(fid,'\r\n\t\t\t]\r\n');
        end
        %% get info about sessions
        % a group of sessions from the same day is called a setlist and
        % will have the same date
        if any(ismember(sessionIdx,procedureRange(2:end)))
            sessionIds=find(ismember(sessionIdx,procedureRange(2:end)));
            for sessionnNum=1:numel(sessionIds)
                %% Important note about naming conventions %%
                % The code below is listing sessions from the spreadsheet, 
                % and will look (l. 255 below) for files in the directory 
                % that match the expected filename. 
                % Specify your file naming convention in the code below, and
                % fill the spreadsheet accordingly.
                
                % The file base name is the name used for all data (e.g.,
                % ephys, behavior, video) associated to a given recording.

                rec.Subject = xpNotesHeader.SubjectID{1};
                rec.Session = replace(char(xpNotes.Procedure(procedureIdx(procNum))),' ','');
                rec.Notes = xpNotes.Notes(sessionIdx(sessionIds(sessionnNum)));
                shortNotes=strsplit(rec.Notes,{' ',','});
                shortNotes=strcat(shortNotes{1:min([2 numel(shortNotes)])});
                rec.Date = char(datetime(xpNotes.Date(procedureIdx(procNum)),'Format','MMdd'));
                rec.Depth = num2str(-xpNotes.Depth(sessionIdx(sessionIds(sessionnNum))));
                rec.Coordinates = num2str(...
                    [xpNotes.APcoord(sessionIdx(sessionIds(sessionnNum))),...
                    xpNotes.MLcoord(sessionIdx(sessionIds(sessionnNum)))]);
                if ~isnan(str2double(rec.Depth))
                    baseName = [rec.Subject '_' rec.Date '_' rec.Depth];
                else
                    baseName = [rec.Subject '_' rec.Date '_' shortNotes]; % '_' rec.Session
                end
                % Start entering info into "session"
                sessions(sessionIds(sessionnNum)).subject=rec.Subject;
                sessions(sessionIds(sessionnNum)).description= [rec.Session ' session for project goal ' xpNotesHeader.Goal{:}];
                sessions(sessionIds(sessionnNum)).shortDate=rec.Date;
                sessions(sessionIds(sessionnNum)).shortNotes=shortNotes;
                sessions(sessionIds(sessionnNum)).baseName=baseName;

                if sessionnNum>1 && strcmp(sessions(sessionIds(sessionnNum)).baseName,...
                        sessions(sessionIds(sessionnNum-1)).baseName)
                    if ~isempty(xpNotes.Comments(sessionIdx(sessionIds(sessionnNum))))
                        sessions(sessionIds(sessionnNum)).baseName= [...
                            sessions(sessionIds(sessionnNum)).baseName...
                            '_' char(xpNotes.Comments(sessionIdx(sessionIds(sessionnNum))))];
                    else
                        sessions(sessionIds(sessionnNum)).baseName=[...
                            xpNotesHeader.SubjectID{1} '_',...
                            char(datetime(xpNotes.Date(procedureIdx(procNum)),'Format','MMdd')) '_'...
                            num2str(-xpNotes.Depth(sessionIdx(sessionIds(sessionnNum)))+1)];
                    end
                end

                sessions(sessionIds(sessionnNum)).fullDate=xpNotes.Date(procedureIdx(procNum));
                recNotes=xpNotes.Notes(procedureIdx(procNum));
                sessions(sessionIds(sessionnNum)).probe=regexp(recNotes,'.+(?= &)','match','once');
                sessions(sessionIds(sessionnNum)).adapter=regexp(recNotes,'(?<=& ).+','match','once');
                sessions(sessionIds(sessionnNum)).AP=xpNotes.APcoord(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).ML=xpNotes.MLcoord(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).depth=xpNotes.Depth(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).stimPower=xpNotes.StimPower(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).stimFreq=xpNotes.StimFreq(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).pulseDur=xpNotes.PulseDur(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).stimDevice=xpNotes.Device(sessionIdx(sessionIds(sessionnNum)));
                sessions(sessionIds(sessionnNum)).comments=xpNotes.Comments(sessionIdx(sessionIds(sessionnNum)));
            end
        end
    else
        fprintf(fid,'\r\n');
    end
    if procNum<numel(procedureIdx)
        fprintf(fid,'\t\t},\r\n');
    else
        fprintf(fid,'\t\t}\r\n');
    end
end
% close Procedures list
fprintf(fid,'\t],\r\n');

%% 4. Write down Sessions
if exist('sessions','var')
    % validate files existence
    fileList=dir([fileDir filesep '**' filesep]);
    fileList=fileList(~[fileList.isdir]);
    [~,fileList,fileFormat] = cellfun(@(fileName) fileparts(fileName), {fileList.name}, 'UniformOutput', false);
    [fileList,fIdx]=unique(fileList');
    fileFormat=fileFormat(fIdx);

    for fileNum=1:size(sessions,2)
        % compare base name with available file names, in different ways (nomenclatures vary)
        fullDate_baseName=[sessions(fileNum).subject '_' datestr(sessions(fileNum).fullDate,'mmddyy') '_' num2str(abs(sessions(fileNum).depth))];
        fileIdx={(cellfun(@(fileName) any(strcmpi(fileName,{sessions(fileNum).baseName,fullDate_baseName})), fileList));...
        (cellfun(@(fileName) contains(fileName,sessions(fileNum).baseName,'IgnoreCase',true), fileList));...
        (cellfun(@(fileName) contains(fileName,sessions(fileNum).shortNotes,'IgnoreCase',true), fileList));...
        (cellfun(@(fileName) contains(sessions(fileNum).baseName,fileName,'IgnoreCase',true), fileList))};
        if ~isempty(find(cellfun(@any,fileIdx),1))
            switch find(cellfun(@any,fileIdx),1)
                case 1
                    fileIdx=fileIdx{1};
                case 2
                    fileIdx=fileIdx{2};
                case 3
                    fileIdx=fileIdx{3};
                case 4
                    fileIdx=fileIdx{4};
            end
        else
            disp(['File ' sessions(fileNum).baseName ' could not be located']);
%             continue
        end
        recList=fileList(fileIdx);
        % remove none rec formats first
        recList=recList(~contains(fileFormat(fileIdx),{'.xlsx','.csv','.avi','mp4'}));
        if ~isempty(recList)
        % then sort by length
        lengthfileName=cellfun(@length, recList);
        sessions(fileNum).baseName=recList{lengthfileName==min(lengthfileName)};
%         if sum(fileIdx)>1
%             disp(['Files ' fileList{fileIdx} ' have the same basename']);
%         end
        else
            sessions(fileNum).baseName=lower(sessions(fileNum).baseName);
        end
    end

    fprintf(fid,'\t"Sessions": [ \r\n');
    str=strrep(jsonencode(sessions),',"',sprintf(',\r\n\t\t"'));
    str=strrep(str,'},{',sprintf('\r\n\t\t},\r\n\t\t{'));
    fprintf(fid,'%s%s%s',sprintf('\t\t'), str(2:end-1), sprintf('\r\n\t]\r\n'));
end
%close file
fprintf(fid,'}');
fclose(fid);

