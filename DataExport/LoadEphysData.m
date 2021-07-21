function [rec,data,spikes,TTLs] = LoadEphysData(fname,dname)
currDir=cd;
cd(dname);
spikes=struct('clusters',[],'electrodes',[],'spikeTimes',[],'waveForms',[],'metadata',[]);
try
wb = waitbar( 0, 'Reading Data File...' );
    rec.dirName=dname;
    rec.fileName=fname;
    disp(['loading ' dname filesep fname]);
    if contains(fname,'.ns') %% Blackrock raw data
        [data,rec,spikes]=LoadEphys_Blackrock(fname);
    elseif contains(fname,{'.bin','dat'}) %% Binary file (e.g., from Intan)
        [data,rec,spikes]=LoadEphys_Binary(dname,fname);
    elseif contains(fname,{'raw.kwd','kwik'}) %% Kwik format
        [data,rec]=LoadEphys_Kwik(dname,fname);
    elseif contains(fname,'continuous') %% Open Ephys old format
        [data,rec,spikes]=LoadEphys_Continuous(dname,fname);
    elseif contains(fname,'nex') %% TBSI format
        [data,rec]=LoadEphys_TBSI(dname);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% get TTL times and structure    
    waitbar( 0.5, wb, 'getting TTL times and structure');
    try
        TTLs = LoadTTL(fname);
    catch
        TTLs = [];
    end
catch
    %close(wb);
    disp('Failed loading ephys data');
end
cd(currDir);
close(wb);
end
