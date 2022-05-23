function [var_frac_all, var_frac_all_low, var_frac_all_high, rel_adv] = smooth_variants(all_var_matrix, valid_lins, valid_times, lineages, recent_days)

if nargin < 5
    recent_days = 90;
end

[ns, nl, maxt] = size(all_var_matrix);

var_frac_all = zeros(size(all_var_matrix));
var_frac_all_low = zeros(size(all_var_matrix));
var_frac_all_high = zeros(size(all_var_matrix));
other_idx = find(strcmpi(lineages, 'other'));
rel_adv = nan(ns, nl);
for cid = 1:ns
    var_data = squeeze(all_var_matrix(cid, valid_lins(cid, :)>0, :));
    these_lins = find(valid_lins(cid, :)>0);
    val_times = find(valid_times(cid, :)>0); val_times(val_times< (maxt-recent_days)) = [];

    if isempty(val_times)
        var_frac_all(cid, other_idx, :) = 1;
        var_frac_all_low(cid, other_idx, :) = 1;
        var_frac_all_high(cid, other_idx, :) = 1;
        continue;
    end
    if length(these_lins) == 1
         var_frac_all(cid, these_lins, :) = 1;
         var_frac_all_low(cid, these_lins, :) = 1;
         var_frac_all_high(cid, these_lins, :) = 1;
         continue;
     end
         
    if length(val_times) == 1
         var_frac_all(cid, these_lins, :) = var_data./sum(var_data);
         var_frac_all_low(cid, these_lins, :) = var_data./sum(var_data);
         var_frac_all_high(cid, these_lins, :) = var_data./sum(var_data);
         continue;
    end

    var_data = var_data(:, val_times); 
    %var_data = movmean(var_data, 7, 2);
    smoothed = zeros(length(these_lins), maxt);
    for ll=1:length(these_lins)
        yy = csaps(val_times, var_data(ll, :)./sum(var_data, 1), 0.001, 1:maxt, sum(var_data, 1)./max(sum(var_data, 1)));
        yy(yy<0) = 0; yy = movmean(yy, 7);
        smoothed(ll, :) = yy;
    end
    smoothed = smoothed./sum(smoothed, 1);
    var_frac_all(cid, these_lins, :) = smoothed;
    var_frac_all_low(cid, these_lins, :) = smoothed;
    var_frac_all_high(cid, these_lins, :) = smoothed;
    %rel_adv(cid, these_lins(1:end-1)) = betaHat(2, :);
    rel_adv(cid, these_lins) = 0;

%     catch
%         fprintf('|');
%     end
    if(mod(cid,10)==0)
        fprintf('.');
    end
end
% Correct for nans
xx = (isnan(var_frac_all));
[bad_cidx, temp1, temp2] = ind2sub(size(var_frac_all), find(xx(:)));
bad_cidx = unique(bad_cidx);
for cc = 1:length(bad_cidx)
    cid = bad_cidx(cc);
    valid_lins(cid, :) = 0; valid_lins(cid, other_idx) = 1;
    var_frac_all(cid, :, :) = 0; var_frac_all(cid, other_idx, :) = 1;
    var_frac_all_low(cid, :, :) = 0; var_frac_all_low(cid, other_idx, :) = 1;
    var_frac_all_high(cid, :, :) = 0; var_frac_all_high(cid, other_idx, :) = 1;    
end

end

