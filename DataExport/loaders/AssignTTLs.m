function TTLs=AssignTTLs(TTLs)
%% Default convention : 
% 1 - Laser
% 2 - Camera 1
% 3 - Session trials

switch size(TTLs,2) 
    case 1
        if isfield(TTLs,'TTLChannel')
            switch TTLs.TTLChannel
                case 1
                    laserTTL=TTLs;
                    videoTTL=0;
                case 2
                    videoTTL=TTLs;
                    clear laserTTL
            end
        else
            laserTTL=TTLs{1}; %might be laser stim or behavior
            videoTTL=[];
        end
    case 2
        laserTTL=TTLs{1}; %used to be behavior trials in older recordings
        videoTTL=TTLs{2};
    case 3 % other TTL (e.g., touch stim)
        if ~isempty(TTLs{1}.TTLtimes)
            laserTTL=TTLs{1};
        else
            laserTTL=[];
        end
        videoTTL=TTLs{2};
        actuatorTTL = TTLs{3};
    otherwise
        if ~iscell(TTLs)
            videoTTL=TTLs;
            clear laserTTL
        end
end