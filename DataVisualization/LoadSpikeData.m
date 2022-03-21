function spikes=LoadSpikeData(fName,traces,sortDir)

try
    
    %% Kilosort
    if contains(fName,'rez.mat') || contains(fName,'_KS') ||...
            contains(fName,'spikes.npy')
        spikes=LoadSpikes_Kilosort(fName,sortDir);
        
    %% JRClust
    elseif contains(fName,'.csv') || ...
            contains(fName,'_jrc') || ...
            contains(fName,'_res')
        spikes=LoadSpikes_JRClust(fName,traces);
        
    elseif logical(regexp(fName,'Ch\d+.'))
    %% TBSI 
        [~,~,fileExt]=fileparts(fName);
        if contains(fileExt,'.hdf5')
            spikes=LoadSpikes_TBSI(fName);
        else
    %% Spike2
            spikes=LoadSpikes_Spike2(fName);
        end        
    %% Spyking Circus
    elseif contains(fName,'.hdf5')
        spikes=LoadSpikes_SpykingCircus(fName);
        
    %% Matlab processing / export
    elseif contains(fName,'.mat')
        spikes=LoadSpikes_Matlab(fName);
        
    end
    
catch %already extracted
    load(fName);
end