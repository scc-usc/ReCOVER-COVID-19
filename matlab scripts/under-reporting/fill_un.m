warning off;
filled_un = zeros(length(popu), length(idx_weeks));

%%

options = optimoptions(@fmincon,'Algorithm','interior-point', 'MaxFunctionEvaluation', 5000,...
    'CheckGradients',false,'SpecifyObjectiveGradient', false);
nw = length(idx_weeks);
for cid = 1:size(data_4, 1)
    nw = length(idx_weeks);
    Ul = un_lts(cid, :); Uu = un_uts(cid, :);
    Ul(isnan(Ul) | isinf(Ul) | Ul < 1) = 1;
    bad_idx = (isnan(Uu)|isinf(Uu)); Uu(bad_idx) = popu(cid)./data_4(cid, idx_weeks(bad_idx));
%    
%     if ~(any())
%         continue;
%     end
    
    yo = data_4_s(cid, idx_weeks);
    A = zeros(2*(nw-1), nw); b = 1e-5 * ones(2*(nw-1), 1); % To enforce cumulative cases always increase
    for jj=1:nw-1
        A(jj, jj) = yo(jj); A(jj, jj+1) = -yo(jj+1); b(jj) = - min(diff(yo));
        A(nw-1+jj, jj) = -1; A(nw-1+jj, jj+1) = 1;
    end
    
    Uu = min(popu(cid)./yo, Uu);
    %try
    for ts = 1:5
        initx =Ul' + rand(length(Ul), 1).*(Uu'-Ul');
        %xvec = fmincon(@(x)(un_cost(x, Ul', Uu', yo', popu(cid))), initx, A, b, [], [], ones(nw, 1), popu(cid)./yo, [],options);
        [all_xvecs{ts}, fmin(ts), exitflag] = fmincon(@(x)(un_cost(x, Ul', Uu', yo', popu(cid))), initx, A, b, [], [], ones(nw, 1), popu(cid)./yo, [], options);
        if exitflag < 1
            fmin(ts) = Inf;
        end
    end    
    disp('Done');
    [~, best_idx] = min(fmin);
    xvec = all_xvecs{best_idx};
    %catch
    %    xvec = zeros(1, nw);
    %end
    
    filled_un(cid, :) = xvec';
    
end

disp('Done');
% %% Fill in missing values
% empty_idx = (sum(filled_un, 2)< 0.01);
% xx = sum(filled_un(~empty_idx, :).*repmat(popu(~empty_idx), [1 length(idx_weeks)]))./sum(popu(~empty_idx));
% filled_un(empty_idx, :) = repmat(xx, [sum(empty_idx) 1]);
% 
% %% Save to file
% csvwrite(['../results/unreported/' prefix '_all_unreported.csv'], [idx_weeks; filled_un]);

%%
for cid = 1:20%length(popu)
    figure;
    tiledlayout(2, 1);
    nexttile;
    dt = diff(data_4_s(cid, :));
    plot(idx_weeks, [dt(idx_weeks)' filled_un(cid, :)'.*dt(idx_weeks)']);
    title(['Region ' num2str(cid) ': Population = ' num2str(popu(cid))]);
    nexttile;
    plot(idx_weeks, [un_lts(cid, :)' un_uts(cid, :)']); hold on;
    plot(true_uns(cid, :)', 'o');  hold off;
    hold off;
    title(['Country ' num2str(cid)]); ylim([0, 20]);
end

%% Test values
L = un_cost(xvec, Ul', Uu', yo', popu(cid));
%%
function [L] = un_cost(xvec, Ul, Uu, yo, N)
nw = length(xvec);
u = xvec(1:nw);
y = u.*yo;
ny = diff(y);
L = 100*sum((u - (Ul+Uu)./2).^2 .* exp(-(Uu-Ul)));
%L = L + sum((diff(u)./u(1:nw-1)).^2); % Regularization term to enforce smoothness over time
%L = L + sum((ny(2:nw-1))./(ny(1:nw-2)+1).^2); % Regularization term to enforce smoothness over time
end