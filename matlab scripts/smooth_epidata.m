function [data_4_s] = smooth_epidata(data_4, smooth_factor)
%SMOOTH_EPIDATA removes outliers and smoothes
deldata = diff(data_4');
deldata(deldata < 0) = 0;
% for cid = 1:size(data_4, 1)
%     neg_idx = find(deldata(cid, :) < 0);
% end

if isnumeric(smooth_factor)
    cleandel = filloutliers(deldata, 'center', 'movmean', smooth_factor, 'ThresholdFactor', 2)';
    data_4_s = [data_4(:, 1) cumsum(movmean(cleandel, smooth_factor, 2), 2)];
else
    cleandel = filloutliers(deldata, 'center', 'movmean', 14);
    t = sgolayfilt(cleandel, 1, 7)';
    data_4_s = [data_4(:, 1)  cumsum(movmean(t, 7, 2), 2)];
end
end

