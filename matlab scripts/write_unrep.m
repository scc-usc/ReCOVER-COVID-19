dest_path = '..\results\unreported\';
%%
prefix = 'global';
eval(['load ' prefix '_unreported.mat']);
%%
uns = zeros(length(countries), 1);

good_cid = st_mid_end(:, 4)<0.15 & un_fact_f(:, 3) > 0.01;
def_un = median(1./un_fact_f(good_cid, 2));

uns(:, 1) = def_un;
uns(good_cid, 1) = 1./un_fact_f(good_cid, 2);

writematrix(uns, [dest_path prefix 'unreported.txt']);

