function commonStr = GetCommonString(allFileNames)
% find common string with cell array of strings
commonStr = allFileNames{1}(all(~diff(char(allFileNames(:)))));
if isempty(commonStr) %not all files have the same name root
    for strCompLength=1:numel(allFileNames{1})
        compIndex=sum(vertcat(cell2mat(cellfun(@(fileName) regexp(allFileNames{1}(1:strCompLength),...
            fileName(1:min([strCompLength, numel(fileName)]))),allFileNames(2:end),'un',0))));
        if strCompLength>1
            if compIndex<prevCompIndex %first decline
                break
            end
        end
        prevCompIndex=compIndex;
    end
    commonStr=allFileNames{1}(1:strCompLength-1);
end
