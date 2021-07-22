function TTLs=LoadEphys_Trials(fName)
wb = waitbar( 0, 'Reading Data File...' );

%% TTLs
waitbar( 0.5, wb, 'getting TTL times and structure');

try
    load([fName{:} '_trials.mat']);
catch
    TTLs=[];
end

close(wb);