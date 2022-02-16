function [TTLtimes,TTLdur]=ContinuousToTTL(continuousTrace,samplingRate,option)

    [TTLtimes,TTLdur] = deal(cell(size(continuousTrace,1),1));
    for traceNum = 1:size(continuousTrace,1)
        %Set threshold high enough to be above any bleedthrough from other analog channels
        threshold = rms(continuousTrace(traceNum,:)) * 20;
        TTLs = logical(continuousTrace(traceNum,:) > threshold); 
        TTLsProperties = regionprops(TTLs, 'Area', 'PixelIdxList');

        % Remove artifacts
        % -----------------------------------------------------------------
        % Assume pulses are triggered at regular interval 
        if strcmp(option,'regularinterval')
            TTLdiffs = diff(cellfun(@(timeIndex) timeIndex(1), {TTLsProperties.PixelIdxList}));
            pulseFreq = median(TTLdiffs);
            TTLsProperties = TTLsProperties(TTLdiffs > pulseFreq*0.95);
            
        % Else assume pulses are regular in duration and longer than transient artifacts
        % artifacts defined as peaks < 1ms (for sampling rate > 1kHz) or <= 1ms for
        % 1kHz sampling rate. Also remove peaks > pulse duration + 1ms.
        else
            pulseDur = mode([TTLsProperties.Area]);
            sF = samplingRate / 1000;
            if samplingRate <= 1000
                TTLsProperties = TTLsProperties([TTLsProperties.Area] >= max([(pulseDur-(1*sF)) 1*sF]) & [TTLsProperties.Area] <= (pulseDur+(1*sF)));
            elseif pulseDur==2 %bare min
                TTLsProperties = TTLsProperties([TTLsProperties.Area] >= pulseDur);
            else
                TTLsProperties = TTLsProperties([TTLsProperties.Area] > max([(pulseDur-(1*sF)) 1*sF]) & [TTLsProperties.Area] <= (pulseDur+(1*sF)));
            end
        end
        TTLtimes{traceNum} = cellfun(@(timeIndex) timeIndex(1), {TTLsProperties.PixelIdxList});
        TTLdur{traceNum} = [TTLsProperties.Area];
    end

    if strcmp(option,'keepfirstonly') || strcmp(option,'regularinterval')
        TTLtimes = TTLtimes{1};
        TTLdur = TTLdur{1};
    end
    
    % For continuous, regular camera pulses with narrow pulse width,
    % some camera exposures are so narrow (e.g. 60 us) that 30 kHz
    % sampling rate only receives 1-2 high signal samples, possible to omit pulses
    if strcmp(option,'regularinterval')
        % Find putative first pulse in the train
        first_pulse = find(diff(TTLtimes) > pulseFreq*0.95 & diff(TTLtimes) < pulseFreq*1.05, 1, 'first');
        
        % Find putative last pulse in the train
        last_pulse = find(diff(TTLtimes) > pulseFreq*0.95 & diff(TTLtimes) < pulseFreq*1.05, 1, 'last');
        
        % Remove artifacts outside the pulse train
        TTLtimes = TTLtimes(first_pulse:last_pulse+1);
        TTLdur = TTLdur(first_pulse:last_pulse+1);
        
        % Find missing pulses
        missingPulses = find(diff(TTLtimes) > pulseFreq*1.5);
        cnt = 0;
        for p = 1:numel(missingPulses)
            missingPulses(p) = missingPulses(p) + cnt;
            cnt = cnt + 1;
        end
        
        % Interpolate missing pulses
        xq = 1:numel(TTLtimes) + numel(missingPulses);
        x = xq;
        x(missingPulses + 1) = [];
        TTLtimes = shiftdim(interp1(x, TTLtimes, xq, 'linear'));
        TTLdur = shiftdim(interp1(x, TTLdur, xq, 'linear'));
        TTLdur(missingPulses + 1) = 0;
    end

    if false
        figure; hold on 
        plot(continuousTrace(1,:)); % plot(continuousTrace(2,:))
        threshold = rms(continuousTrace(1,:))*20;
        yline(threshold)
    end

end