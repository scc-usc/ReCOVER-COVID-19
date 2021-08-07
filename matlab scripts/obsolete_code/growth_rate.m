function [s_val, s_conf, fC, s_val_lin, s_conf_lin, fC_lin, MM, MM_lin] = growth_rate(rat_data)

func = @(b, x)(b(2)*exp(b(1)*(x-420)));

s_val = cell(size(rat_data, 1), 1);
s_conf = cell(size(rat_data, 1), 1);
fC = cell(size(rat_data, 1), 1);
MM = cell(size(rat_data, 1), 1);

for cid = 1:size(rat_data, 1)
    s_val{cid} = nan(1, 2);
    s_conf{cid} = nan(2, 2);
    s_val_lin{cid} = nan(1, 2);
    s_conf_lin{cid} = nan(2, 2);

    yy = rat_data(cid, :);
    nnanidx = intersect(find(~isnan(yy)), find(yy>0.00)); nnanidx(nnanidx<385) = [];
    
%     if cid==11
%         debug_val = 1;
%     end
    
    if length(nnanidx)<5
        continue;
    end
    
    try
    mdl = fitnlm(nnanidx, yy(nnanidx), func, [0 0]);
    s_val{cid} = mdl.Coefficients.Estimate;
    s_conf{cid} = mdl.coefCI;
    [ypred,yci] = predict(mdl,nnanidx');
    fC{cid} = [nnanidx', yy(nnanidx)', yci(:, 1), ypred, yci(:, 2)];
    MM{cid} = mdl;
    mdl1 = fitlm(nnanidx, log(yy(nnanidx)));
    s_val_lin{cid} = mdl1.Coefficients.Estimate;
    s_conf_lin{cid} = mdl1.coefCI;
    [ypred,yci] = predict(mdl1, nnanidx');
    fC_lin{cid} = [nnanidx', yy(nnanidx)', exp(yci(:, 1)), exp(ypred), exp(yci(:, 2))];
    MM_lin{cid} = mdl1;
    catch
        continue;
    end
end

