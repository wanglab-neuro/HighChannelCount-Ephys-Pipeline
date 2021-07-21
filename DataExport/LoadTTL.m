function TTLs = LoadTTL(fName)
% get TTL times and structure
% userinfo=UserDirInfo;
TTLs=struct('start',[],'end',[],'interval',[],'sampleRate',[],'continuous',[]);
if contains(fName,'raw.kwd')

elseif contains(fName,'.mat')

elseif contains(fName,'continuous')

elseif contains(fName,'.bin')

elseif contains(fName,'nex')

elseif contains(fName,'.npy')
    %     cd('..\..');

elseif contains(fName,'.ns') || contains(fName,'.nev')

end

