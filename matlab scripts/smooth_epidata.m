function [data_4_s] = smooth_epidata(data_4, smooth_factor, week_correction, week_smoothing)
%SMOOTH_EPIDATA removes outliers and smoothes

if nargin < 4
    week_smoothing = 1;
end

if nargin < 3
    week_correction = 1;
end

deldata = diff(data_4');
%deldata(deldata < 0) = 0;
data_4_s = data_4;
maxt = size(data_4, 2);
date_map = ceil(((1:maxt-1) - mod(maxt-1, 7))/7);
if isnumeric(smooth_factor)
    cleandel = deldata;
    if week_correction == 1
        for cid = 1:size(data_4, 1)
            week_dat = diff(data_4(cid, mod(maxt-1, 7)+1:7:maxt)');
            [clean_week, TF] = filloutliers(week_dat, 'linear', 'movmedian', 20, 'ThresholdFactor', 3);
            [~, peak_idx] = findpeaks([week_dat; 0]);
            tf_vals = intersect(find(TF), peak_idx);
            for jj=1:length(tf_vals)
                cleandel(date_map==tf_vals(jj), cid) = clean_week(tf_vals(jj))/7;
            end
        end
        deldata = cleandel;
    end
    
    if week_smoothing == 1
            week_dat = diff(data_4(:, mod(maxt-1, 7)+1:7:maxt)');
            for jj=1:size(week_dat, 1)
                deldata(date_map==jj, :) = repmat(week_dat(jj, :)/7, [7 1]);
            end
    end
    
    %cleandel = filloutliers(deldata, 'center', 'movmean', smooth_factor*2, 'ThresholdFactor', 3);
    %cleandel = filloutliers(deldata, 'linear', 'movmean', smooth_factor*2, 'ThresholdFactor', 3);
    deldata(deldata < 0) = 0;
    data_4_s = [data_4(:, 1) cumsum(movmean(movmean(deldata', smooth_factor, 2), smooth_factor, 2), 2)];
else
    %cleandel = filloutliers(deldata, 'center', 'movmedian', 14);
    cleandel = deldata;
    for cid = 1:size(data_4, 1)
        t = smooth(cleandel(:, cid),0.1,'rloess')';
        data_4_s(cid, :) = [data_4(cid, 1) cumsum(t, 2)];
    end
end
end

