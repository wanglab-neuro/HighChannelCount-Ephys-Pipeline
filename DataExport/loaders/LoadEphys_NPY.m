function TTLs=LoadEphys_NPY(dName)
wb = waitbar( 0, 'Reading Data File...' );

%% TTLs
waitbar( 0.5, wb, 'getting TTL times and structure');

% readNPY('.npy');

exportDirListing=dir(dName); %regexp(cd,'\w+$','match')
TTLs=importdata(exportDirListing(~cellfun('isempty',cellfun(@(x) contains(x,'_trials.'),...
    {exportDirListing.name},'UniformOutput',false))).name);

close(wb);