function [rec,data,spikes,TTLs] = LoadEphysData(fName,dName)
currDir=cd; cd(dName);

try
    disp(['loading ' fullfile(dName,fName)]);

    if contains(fName,'.ns') %% Blackrock raw data
        [data,rec,spikes,TTLs]=LoadEphys_Blackrock(dName,fName);
    elseif contains(fName,{'.bin','dat'}) %% Binary file (e.g., from Intan)
        [data,rec,spikes,TTLs]=LoadEphys_Binary(dName,fName);
    elseif contains(fName,{'raw.kwd','kwik'}) %% Kwik format
        [data,rec,TTLs]=LoadEphys_Kwik(dName,fName);
    elseif contains(fName,'continuous') %% Open Ephys old format
        [data,rec,spikes,TTLs]=LoadEphys_Continuous(dName,fName);
    elseif contains(fName,'nex') %% TBSI format
        [data,rec,TTLs]=LoadEphys_TBSI(dName,fName);
    elseif contains(fName,'.mat') %trials only
        [rec,data,spikes]=deal([]);
        TTLs=LoadEphys_Trials(fName);
    elseif contains(fName,'.npy') %trials only
        [rec,data,spikes]=deal([]);
        TTLs=LoadEphys_NPY(dName);
    end

catch
    disp('Failed loading ephys data');
end
cd(currDir);
end
