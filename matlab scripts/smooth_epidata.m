function [data_4_s] = smooth_epidata(data_4, smooth_factor)
%SMOOTH_EPIDATA removes outliers and smoothes
deldata = diff(data_4');
deldata(deldata < 0) = 0;
data_4_s = data_4;

if isnumeric(smooth_factor)
    cleandel = filloutliers(deldata, 'center', 'movmedian', smooth_factor, 'ThresholdFactor', 2)';
    data_4_s = [data_4(:, 1) cumsum(movmean(cleandel, smooth_factor, 2), 2)];
else
    cleandel = filloutliers(deldata, 'center', 'movmedian', 14);
    
    for cid = 1:size(data_4, 1)
        t = smooth(cleandel(:, cid),0.2,'rloess')';
        data_4_s(cid, :) = [data_4(cid, 1) cumsum(t, 2)];
    end
end
end

