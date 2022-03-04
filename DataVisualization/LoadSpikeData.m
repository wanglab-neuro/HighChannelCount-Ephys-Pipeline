function spikes=LoadSpikeData(argin_fName,traces,sortDir)

%% Kilosort
if contains(argin_fName,'rez.mat') || contains(argin_fName,'_KS') ||...
        contains(argin_fName,'spikes.npy') 
    spikes=LoadSpikes_Kilosort(argin_fName,sortDir);

%% from JRClust
elseif contains(argin_fName,'.csv') || ...
        contains(argin_fName,'_jrc') || ...
        contains(argin_fName,'_res') 
    spikes=LoadSpikes_JRClust(argin_fName,traces);

%% TBSI format
elseif logical(regexp(argin_fName,'Ch\d+.'))  
    spikes=LoadSpikes_TBSI(argin_fName);

%% Spyking Circus
elseif contains(argin_fName,'.hdf5')
    spikes=LoadSpikes_SpykingCircus(argin_fName);   
    
%% Matlab processing / export
elseif contains(argin_fName,'.mat') 
    spikes=LoadSpikes_Matlab(argin_fName);
    
end