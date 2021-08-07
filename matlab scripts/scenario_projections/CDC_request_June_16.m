var_prop{1} = diff(squeeze(nansum(net_var_A, 2))')./diff(squeeze(nansum(net_infec_A, 2))');
var_prop{2} = diff(squeeze(nansum(net_var_B, 2))')./diff(squeeze(nansum(net_infec_B, 2))');
var_prop{3} = diff(squeeze(nansum(net_var_C, 2))')./diff(squeeze(nansum(net_infec_C, 2))');
var_prop{4} = diff(squeeze(nansum(net_var_D, 2))')./diff(squeeze(nansum(net_infec_D, 2))');

var_prop1{1} =  squeeze(nanmean(diff(net_var_A, 1, 3)./diff(net_infec_A, 1, 3), 2));
var_prop1{2} =  squeeze(nanmean(diff(net_var_B, 1, 3)./diff(net_infec_B, 1, 3), 2));
var_prop1{3} =  squeeze(nanmean(diff(net_var_C, 1, 3)./diff(net_infec_C, 1, 3), 2));
var_prop1{4} =  squeeze(nanmean(diff(net_var_D, 1, 3)./diff(net_infec_D, 1, 3), 2));


%%
T_1 = table;
T_1.date = datetime(2021, 5, 29)+(1:horizon-1)';
T_1.scenario = repmat(scen_names(1), [horizon-1 1]);
T_1.proportion_mean = mean(var_prop{1}, 2);
T_1.proportion_min = min(var_prop{1}, [], 2);
T_1.proportion_max = max(var_prop{1}, [], 2);

%%
T_2 = table;
T_2.date = datetime(2021, 5, 29)+(1:horizon-1)';
T_2.scenario = repmat(scen_names(2), [horizon-1 1]);
T_2.proportion_mean = mean(var_prop{2}, 2);
T_2.proportion_min = min(var_prop{2}, [], 2);
T_2.proportion_max = max(var_prop{2}, [], 2);
%%
T_3 = table;
T_3.date = datetime(2021, 5, 29)+(1:horizon-1)';
T_3.scenario = repmat(scen_names(3), [horizon-1 1]);
T_3.proportion_mean = mean(var_prop{3}, 2);
T_3.proportion_min = min(var_prop{3}, [], 2);
T_3.proportion_max = max(var_prop{3}, [], 2);

%%
T_4 = table;
T_4.date = datetime(2021, 5, 29)+(1:horizon-1)';
T_4.scenario = repmat(scen_names(4), [horizon-1 1]);
T_4.proportion_mean = mean(var_prop{4}, 2);
T_4.proportion_min = min(var_prop{4}, [], 2);
T_4.proportion_max = max(var_prop{4}, [], 2);
%%
T_var = [T_1; T_2; T_3; T_4];
%%

ns = size(data_4, 1); nl = length(lineages); maxT = size(data_4, 2);
var_frac_all = zeros(ns, nl, 121);
var_frac_se = nan(ns, nl);
rel_adv = nan(ns, nl);
for cid = 1:ns
    var_data = squeeze(red_var_matrix(cid, valid_lins(cid, :)>0, :));
    these_lins = find(valid_lins(cid, :)>0);
    val_times = find(valid_times(cid, :)>0); val_times(val_times< (maxT-90)) = [];
 %   try
     if size(var_data, 2) == 1
         var_frac_all(cid, these_lins, :) = 1;
     else
    var_data = var_data(:, val_times); 

    [betaHat, stat] = mnrfit(val_times', var_data');
    piHat = mnrval(betaHat, (maxT-30:maxT+90)');
    var_frac_all(cid, these_lins, :) = piHat';
    rel_adv(cid, these_lins(1:end-1)) = betaHat(2, :);
    rel_adv(cid, these_lins(end)) = 0;
     end
%     catch
%         fprintf('|');
%     end
end
%%
val_idx = valid_lins(:, 20)>0;
var_frac_sum = sum(popu(val_idx).*squeeze(var_frac_all(val_idx, 20, :)), 1)/sum(popu(val_idx));
%%
T_5 = table;
T_5.date = datetime(2021, 6, 16)+(-30 : 90)';
T_5.scenario = repmat({'Estimated'}, [121 1]);
T_5.proportion_mean = var_frac_sum';
T_5.proportion_min = var_frac_sum';
T_5.proportion_max =  var_frac_sum';
%%
T_var = [T_var; T_5];