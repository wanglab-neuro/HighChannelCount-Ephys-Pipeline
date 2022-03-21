function spikes=LoadSpikes_Kilosort(fileName,sortDir)

    switch fileName
        case 'spike_times.spikes.npy'
            phyData = loadPhy(sortDir);
            spikes.times=phyData.spike_times; %readNPY(argin_fName);
            spikes.unitID=phyData.spike_clusters+1; %readNPY(fullfile(sortDir,'spike_clusters.npy'));
            %             unitIDs=unique(spikes.unitID);
            %             templates=phyData.templates;
            %             templateToEl=zeros(numel(unitIDs),1);
            %             for templNum=1:numel(unitIDs)
            %                 thatTemplate=squeeze(templates(:,:,unitIDs(templNum)));
            %                 [elecRow,~] = ind2sub(size(thatTemplate),find(thatTemplate==max(max(thatTemplate))));
            %                 if size(elecRow,1)>1
            %                     if length(unique(elecRow))>1 %weird
            %                         %                     then look for next biggest value?
            %                         return
            %                     else
            %                         elecRow=unique(elecRow);
            %                     end
            %                 end
            %                 templateToEl(templNum)=elecRow;
            %             end
            %             spikes.preferredElectrode=nan(numel(spikes.times),1);
        otherwise
            load(fileName);
            spikes.times=uint64(rez.st3(:,1));
            spikes.unitID=uint32(rez.st3(:,2));
            unitIDs=unique(spikes.unitID);
            templates=abs(rez.Wraw);
            templateToEl=zeros(numel(unitIDs),1);
            for templNum=1:numel(unitIDs)
                thatTemplate=squeeze(templates(:,:,unitIDs(templNum)));
                [elecRow,~] = ind2sub(size(thatTemplate),find(thatTemplate==max(max(thatTemplate))));
                if size(elecRow,1)>1
                    if length(unique(elecRow))>1 %weird
                        %                     then look for next biggest value?
                        return
                    else
                        elecRow=unique(elecRow);
                    end
                end
                templateToEl(templNum)=elecRow;
            end
            spikes.preferredElectrode=nan(numel(spikes.times),1);
            for unitNum=1:numel(unitIDs)
                spikes.preferredElectrode(unitIDs(unitNum)==spikes.unitID)=templateToEl(unitNum);
            end
    end
    spikes.waveforms=[];
    [spikes.samplingRate,spikes.timebase]=deal(30000);
    [spikes.times,timeIdx]=sort(spikes.times);
    spikes.unitID=spikes.unitID(timeIdx);
    if isfield(spikes,'preferredElectrode')
        spikes.preferredElectrode=spikes.preferredElectrode(timeIdx);
    end

end