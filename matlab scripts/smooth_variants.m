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

    var_data = full(var_data(:, val_times)); 
    %var_data = movmean(var_data, 7, 2);
    smoothed = zeros(length(these_lins), maxt);
    for ll=1:length(these_lins)
        yy = csaps(val_times, var_data(ll, :)./sum(var_data, 1), 0.001, 1:maxt, sum(var_data, 1)./max(sum(var_data, 1)));
        fd = find(var_data(ll, :)>0);  % Before the first observation, the estimate must be zero
        if length(fd) > 1
            fd = val_times(fd(1));
            %yy(1:fd-1) = 0;
        end
        yy(yy<0) = 0; yy = movmean(yy, 7);
        smoothed(ll, :) = yy;
       
        
    end
    smoothed = smoothed./sum(smoothed, 1);
    
    try
        tw = 70; % Last 70 days to fit logistic model
        val_times1 = val_times(val_times > maxt-tw); var_data1 = var_data(:, val_times > maxt-tw);
        
        try
            [betaHat, ~, stat] = mnrfit(val_times1', var_data1', 'EstDisp','on');
            [piHat, dlow, dhigh] = mnrval(betaHat, (maxt-tw+1:maxt)', stat); piHat = piHat';
        catch
            [betaHat] = mnrfit(val_times1', var_data1'); 
            [piHat] = mnrval(betaHat, (maxt-tw+1:maxt)'); piHat = piHat';
            dlow = 0; dhigh = 0;
        end
        
        mgd = [smoothed(:, 1:end-tw) piHat];
        mgd = movmean(mgd, 7, 2);

        mgdl = [smoothed(:, 1:end-tw) max(piHat-dlow', 0)];
        mgdl = movmean(mgdl, 7, 2);

        mgdh = [smoothed(:, 1:end-tw) min(piHat+dhigh', 1)];
        mgdh = movmean(mgdh, 7, 2);

        rel_adv(cid, these_lins(1:end-1)) = betaHat(2, :);
    catch
        mgd = smoothed;
        mgdl = mgd;
        mgdh = mgd;
        rel_adv(cid, these_lins) = 0;
    end
        
    var_frac_all(cid, these_lins, :) = mgd;
    var_frac_all_low(cid, these_lins, :) = mgdl;
    var_frac_all_high(cid, these_lins, :) = mgdh;

    
    

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

