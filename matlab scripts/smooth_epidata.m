function [data_4_s] = smooth_epidata(data_4, smooth_factor)
%SMOOTH_EPIDATA removes outliers and smoothes
deldata = diff(data_4');
deldata(deldata < 0) = 0;
data_4_s = data_4;
maxt = size(data_4, 2);
date_map = ceil(((1:maxt-1) - mod(maxt-1, 7))/7);
if isnumeric(smooth_factor)
     cleandel = deldata;
    for cid = 1:size(data_4, 1)
        week_dat = diff(data_4(cid, mod(maxt-1, 7)+1:7:maxt)');
        [clean_week, TF] = filloutliers(week_dat, 'linear', 'movmedian', 8, 'ThresholdFactor', 2);
        [~, peak_idx] = findpeaks([week_dat; 0]);
        tf_vals = intersect(find(TF), peak_idx);
        for jj=1:length(tf_vals)
            cleandel(date_map==tf_vals(jj), cid) = clean_week(tf_vals(jj))/7;
        end
    end
    deldata = cleandel;
    cleandel = filloutliers(deldata, 'center', 'movmean', smooth_factor*2, 'ThresholdFactor', 2);
    data_4_s = [data_4(:, 1) cumsum(movmean(cleandel', smooth_factor, 2), 2)];
else
    %cleandel = filloutliers(deldata, 'center', 'movmedian', 14);
    cleandel = deldata;
    for cid = 1:size(data_4, 1)
        t = smooth(cleandel(:, cid),0.1,'rloess')';
        data_4_s(cid, :) = [data_4(cid, 1) cumsum(t, 2)];
    end
end
end

