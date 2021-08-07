function [peak_test] = unreported_reliability_test(truedat, N, gbar, beta, del3, jp)
peak_test = -1;


[~, idx] = max(diff(truedat)); % Approximate peak location
peakval = truedat(idx);
xx = peakval./(N*(1-1/(jp*beta(1))));


peak_test = (1-del3)*xx < gbar & (1+del3)*xx > gbar;

% If the max value is at the end, then it is not the peak. A high number
% like 10 is chosen to ensure the peak is not due to noise.
if idx > length(truedat) - 10 
    peak_test = -1;
end
end

