function recSettings = readOpenEphysXMLSettings(fname)

readXMLSettings=parseXML(fname);
readXMLSettings=readXMLSettings.Children(~cellfun(@(fieldNames) ...
    contains(fieldNames,'#text'), {readXMLSettings.Children.Name})); %remove fluff

%could also get simple information like recording name by text mining, 
%searching fo fields like: 
%recordPath="C:\Data\vIRt22" prependText="vIRt22" appendText="5300_50ms1Hz10mW"

for fieldNum=1:numel(readXMLSettings)
    if ~isempty(readXMLSettings(fieldNum).Attributes)
        recSettings.(lower(readXMLSettings(fieldNum).Name))=readXMLSettings(fieldNum).Attributes;
    else
        keepFields=~cellfun(@(fieldNames) contains(fieldNames,'#text'),...
            {readXMLSettings(fieldNum).Children.Name});
        switch readXMLSettings(fieldNum).Name
            case 'INFO'
%                 recSettings.setupInfo=struct;
                for subFieldNum=find(keepFields)
                    recSettings.setupinfo.(lower(readXMLSettings(fieldNum).Children(subFieldNum).Name))=...
                        readXMLSettings(fieldNum).Children(subFieldNum).Children.Data;
                end
            case 'SIGNALCHAIN'
                sourceTypeNameIdx=contains(...
                    {readXMLSettings(fieldNum).Children(2).Attributes.Name},'libraryName');
                sourceType=readXMLSettings(...
                    fieldNum).Children(2).Attributes(sourceTypeNameIdx).Value;
                switch sourceType
                    case 'Rhythm FPGA'
                        recSettings.signals=struct;
                        % then dive in Processors
                        for subFieldNum=find(keepFields)
                            if ~isempty(readXMLSettings(fieldNum).Children(subFieldNum).Children)
                                pluginTypeNameIdx=contains(...
                                    {readXMLSettings(fieldNum).Children(subFieldNum).Attributes.Name},'pluginName');
                                pluginType=readXMLSettings(...
                                    fieldNum).Children(subFieldNum).Attributes(pluginTypeNameIdx).Value;
                                pluginType(isspace(pluginType)) = [];
                                %                                 recSettings.signals.(pluginType)=struct;  
                                switch pluginType
                                    case 'RhythmFPGA'
                                        recSettings.signals.channelInfo=struct;
                                        channelInfo=...
                                            readXMLSettings(fieldNum).Children(...
                                            subFieldNum).Children(2).Children;
                                        channelIdx=~cellfun(@(fieldNames) contains(fieldNames,'#text'),{channelInfo.Name});
                                        channelInfo=[channelInfo(channelIdx).Attributes];
                                        channelNumber={channelInfo(contains({channelInfo.Name},'number')).Value}';
                                        channelName={channelInfo(contains({channelInfo.Name},'name')).Value}';
                                        channelGain={channelInfo(contains({channelInfo.Name},'gain')).Value}';
                                        recSettings.signals.channelInfo=table(channelNumber,channelName,channelGain);
                                        recSettings.signals.channelInfo.channelNumber=...
                                            str2double(recSettings.signals.channelInfo.channelNumber);
                                    case 'ChannelMap' %TBD
%                                         recSettings.signals.channelMap=struct;
                                        mappingEditorIdx=contains({readXMLSettings(...
                                            fieldNum).Children(subFieldNum).Children.Name},'EDITOR');
                                        keepSubFields=find(cellfun(@(fieldNames) contains(fieldNames,'CHANNEL'),...
                                            {readXMLSettings(fieldNum).Children(...
                                            subFieldNum).Children(mappingEditorIdx).Children.Name}));
                                        for SecondOrderSubFieldNum=1:numel(keepSubFields)
                                            mappingInfo(SecondOrderSubFieldNum,1:2)=[...
                                            str2double(readXMLSettings(fieldNum).Children(...
                                            subFieldNum).Children(mappingEditorIdx).Children(...
                                            keepSubFields(SecondOrderSubFieldNum)).Attributes(3).Value),...                  
                                            str2double(readXMLSettings(fieldNum).Children(...
                                            subFieldNum).Children(mappingEditorIdx).Children(...
                                            keepSubFields(SecondOrderSubFieldNum)).Attributes(2).Value)];
                                        end
                                            try
                                                recSettings.signals.channelInfo.Mapping(ismember(mappingInfo(:,1),...
                                                [recSettings.signals.channelInfo.channelNumber]))=...
                                                mappingInfo(:,2);
                                            catch
                                                recSettings.signals.channelInfo.Mapping(ismember(mappingInfo(:,1),...
                                                [recSettings.signals.channelInfo.channelNumber]))=...
                                                mappingInfo(ismember(mappingInfo(:,1),...
                                                [recSettings.signals.channelInfo.channelNumber]),2);
                                            end
                                    %case % add more if needed
                                end
                            end
                        end
                end
        end
    end
end
    
    