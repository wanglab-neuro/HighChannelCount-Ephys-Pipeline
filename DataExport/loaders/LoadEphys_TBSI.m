function [data,rec]=LoadEphys_TBSI(dname)
dirBranch=regexp(strrep(dname,'-','_'),['\' filesep '\w+'],'match');

dirlisting = dir(dname);
dirlisting = {dirlisting(:).name};
dirlisting=dirlisting(cellfun('isempty',cellfun(@(x) contains('.',x(end)),dirlisting,'UniformOutput',false)));
%get experiment info from note.txt file
fileID = fopen('note.txt');
noteInfo=textscan(fileID,'%s');
dirBranch{end}=[dirBranch{end}(1) noteInfo{1}{:} '_' dirBranch{end}(2:end)];
%get data info from Analog file
analogFile=dirlisting(~cellfun('isempty',cellfun(@(x) contains(x,'Analog'),dirlisting,'UniformOutput',false)));
analogData=readNexFile(analogFile{:});
rec.dur=size(analogData.contvars{1, 1}.data,1);
rec.samplingRate=analogData.freq;
rawfiles=find(~cellfun('isempty',cellfun(@(x) contains(x,'RAW'),dirlisting,'UniformOutput',false)));
rec.numRecChan=length(rawfiles);
data=nan(rec.numRecChan,rec.dur);
for fnum=1:rec.numRecChan
    richData=readNexFile(dirlisting{rawfiles(fnum)});
    data(fnum,:)=(richData.contvars{1, 1}.data)';
end
rec.sys='TBSI';
