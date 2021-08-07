options = optimoptions('fmincon',"Algorithm","interior-point", 'Display', "final", 'MaxIterations', 20000, ...
    'MaxFunctionEvaluations', 10000, 'SpecifyObjectiveGradient',true, 'SpecifyConstraintGradient',true);
%init_val = [ones(nv, 1)/nv; zeros(nv-1, 1); ones(nv-1, 1); rand(length(val_times), 1)];

new_var_frac_all = zeros(size(var_frac_all));
flag_list = zeros(length(popu), 1);
R0_mat = nan(length(popu), length(lineages));
R1_mat = nan(length(popu), length(lineages));
Y0_mat = nan(length(popu), length(lineages));
X_cell = cell(length(popu), 1); nv_cell = zeros(length(popu), 1); 
for cid = 1:56
    
    ii1 = [0 diff(data_4_s(cid, :))];
    var_data = squeeze(red_var_matrix(cid, valid_lins(cid, :)>0, :));
    
    if sum(valid_lins(cid, :)>0) == 1
        new_var_frac_all(cid, (valid_lins(cid, :)>0), :) = 1;
        disp(['Only one strain for ' countries{cid}]);
        continue;
    elseif sum(valid_lins(cid, :)>0) == 0
        other_idx = find(strcmpi(lineages, 'other'));
        disp(['No data for ' countries{cid}]);
        new_var_frac_all(cid, other_idx, :) = 1;
        continue;
    end
    
    val_times = find(valid_times(cid, 1:end)>0); val_times(val_times< (maxt - 70)) = [];
    
    ii = ii1(val_times)'; %ii = smooth(ii);
    var_data = var_data(:, val_times);
    ig_idx = sum(var_data, 2)./sum(sum(var_data, 2)) <0; var_data(ig_idx, :) = [];
    these_lins = lineages((valid_lins(cid, :)>0)); these_lins(ig_idx) = [];
    nv = size(var_data, 1);
    T = size(var_data, 2);
    base_var = find(strcmpi(these_lins, 'b.1.1.7'));
    %goodX = squeeze(var_frac_all(cid, valid_lins(cid, :)>0, val_times));
    % goodX = squeeze(all_var_est_matrix(cid, valid_lins(cid, :)>0, val_times));
    % goodX = fillmissing(goodX, 'previous', 2);
    goodX = movmean(var_data./sum(var_data), 14, 2);
    
    
    init_val = [max(goodX(:, 1), 1e-20); zeros(nv-1, 1); ones(nv-1, 1); (goodX(base_var, :)')];
    lb = [(1e-20)*ones(nv, 1); -2*ones(nv-1, 1); 0.2 + zeros(nv-1, 1); 1e-20 + zeros(T, 1)];
    ub = [ones(nv, 1); 2*ones(nv-1, 1); 30*ones(nv-1, 1); ones(T, 1)];
    
    Aeq = zeros(1, length(lb)); Aeq(1:nv) = 1; beq = 1;
    A = zeros(2*(nv-1), length(lb)); b = zeros(2*(nv-1), 1);
    for jj=1:nv-1
        A(jj, nv + jj) = 1; A(jj, nv + jj + nv-1) = -1;
        A(jj+nv-1, nv + jj) = -7; A(jj + nv-1, nv + jj + nv-1) = 1; b(jj+nv-1) = 7;
    end
    disp(['Calculating for ' countries{cid}]);
    try
        [X,fval,exitflag,output,lambda,grad,hessian] = fmincon(@(X)(multi_variant_obj_d(X, var_data, val_times, ii, 0, base_var)), ...
            init_val, A, b, Aeq, beq, lb, ub,...
            @(X)(multi_variant_cons_d(X, var_data, val_times, ii, base_var)), options);
        
        flag_list(cid) = exitflag;
        
        [nLL, G, Yhat, Y0, R0, R1] = multi_variant_obj_d(X, var_data, val_times, ii, 0, base_var);
        [c, ceq] = multi_variant_cons_d(X, var_data, val_times, ii, base_var);
        ii1(ii1<1) = 1; ii1 = ii1(:);
        [Yhat1, Y0, R0, R1] = multi_variant_implicit_obj_ex(X, (1:length(ii1)), ii1, base_var, size(var_data, 1), val_times(1));
        tvals = (val_times(1) - 20):length(ii1);
%         figure; h1 = plot(tvals, Yhat1(:, tvals)'); hold on; h2 = plot(val_times, (var_data./sum(var_data, 1))', 'o'); hold off;
%         set(h1, {'color'}, num2cell(hsv(size(var_data, 1)),2)); set(h2, {'color'}, num2cell(hsv(size(var_data, 1)),2));
%         ylabel('Fractional Prevelance');
%         legend(these_lins, 'location', 'northwest'); title(countries{cid})
        new_var_frac_all(cid, (valid_lins(cid, :)>0), :) = real(Yhat1);
        
        R0_mat(cid, (valid_lins(cid, :)>0)) = R0';
        R1_mat(cid, (valid_lins(cid, :)>0)) = R1';
        Y0_mat(cid, (valid_lins(cid, :)>0)) = Y0';
        X_cell{cid} = X; nv_cell(cid) = nv;
        
    catch er
        fprintf('\n%s\n',er.message);
        other_idx = find(strcmpi(lineages, 'other'));
        new_var_frac_all(cid, other_idx, :) = 1;
    end
end