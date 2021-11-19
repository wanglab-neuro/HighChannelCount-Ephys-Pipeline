function recInfo=LoadRecInfo(recInfoFile)
try
    recInfo=load(recInfoFile);
    if any(contains(fields(recInfo),'RecInfo'))
        fldNames=fields(recInfo);
        recInfo=recInfo.(fldNames{contains(fields(recInfo),'RecInfo')}){:};
    else
        recInfo=recInfo.(cell2mat(fields(recInfo)));
    end
catch
    recInfo=jsondecode(fileread(recInfoFile));
end