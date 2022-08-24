udidx = unique(didx);
data_selector = zeros(maxt, 1); data_selector(udidx) = 1;
first_day = find(data_selector); last_day = first_day(end); first_day = first_day(1);

death_vac(~data_selector, :) = nan; 
death_unvac(~data_selector, :) = nan; 

cum_vax_death = cumsum(death_vac, 1, 'omitnan');
cum_unvax_death = cumsum(death_unvac, 1, 'omitnan');

vax_num_dummy(~data_selector, :) = nan;
unvax_num_dummy(~data_selector, :) = nan;

cum_vax_death(~data_selector, :) = nan;
cum_unvax_death(~data_selector, :) = nan;

vax_num_dummy(first_day:last_day, :) = fillmissing(vax_num_dummy(first_day:last_day, :), 'linear', 1);
unvax_num_dummy(first_day:last_day, :) = fillmissing(unvax_num_dummy(first_day:last_day, :), 'linear', 1);

cum_vax_death(first_day:last_day, :) = fillmissing(cum_vax_death(first_day:last_day, :), 'linear', 1);
cum_unvax_death(first_day:last_day, :) = fillmissing(cum_unvax_death(first_day:last_day, :), 'linear', 1);

death_vac = diff(cum_vax_death);
death_unvac = diff(cum_unvax_death);

death_ratio = death_vac./death_unvac;
%%
gg = 5;
yy = death_unvac(first_day:d_last_day, gg);
xx = infec_unvac(first_day:d_last_day, gg);
lrange = 30; tr = 28;
all_alpha = []; TT = []; all_lags = [];
for ii=lrange+tr:7:(length(yy)-tr)
    [aa, ll] = lin_fit(xx, yy, 14, 35, ii:ii+tr);
    all_alpha = [all_alpha; aa];
    all_lags = [all_lags; ll];
    TT = [TT; ii+first_day+tr/2];
end
%%
function [alpha, lag] = lin_fit(X, y, minl, maxl, yrange)
    aa = inf(maxl, 1);
    res = inf(maxl, 1);
    for l=minl:maxl
        [aa(l), res(l)] = lsqlin(X(yrange - l), y(yrange));
    end
    [~, lag] = min(res);
    alpha = aa(lag);
end
