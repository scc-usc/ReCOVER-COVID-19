function [meanMSE, meanMAPE, allMSE, allMAPE] = calc_errors(gtruth1, predvals1, win_size)
    %Calculates RMSE and Symmetric MAPE for forecasts
    
    if nargin < 3
        win_size = 1;
    end
    
    if win_size < 2    % Evaluate daily forecasts
        gtruth = gtruth1; predvals = predvals1;
        allMSE = nanmean((gtruth-predvals).^2, 2);
        meanMSE = (nanmean(sqrt(allMSE)));
        allMAPE = nanmean(abs(gtruth-predvals)./(0.5*gtruth+0.5*predvals+ 1e-5), 2);
        meanMAPE = nanmean(allMAPE);
    else    % Evaluate forecasts in buckets (e.g., weekly)
        tt = floor(size(gtruth1, 2)/win_size);
        allMSE = zeros(size(gtruth1, 1), 1);
        allMAPE = zeros(size(gtruth1, 1), 1);
        for jj=1:tt
            gtruth = sum(gtruth1(:, win_size*(jj-1) + 1 : win_size*jj), 2);
            predvals = sum(predvals1(:, win_size*(jj-1) + 1 : win_size*jj), 2);
            allMSE = allMSE + (gtruth-predvals).^2 / tt;
            allMAPE = allMAPE + (1/tt)*abs(gtruth-predvals)./(0.5*gtruth+0.5*predvals+ 1e-5);
        end
        meanMSE = (nanmean(sqrt(allMSE)));
        meanMAPE = nanmean(allMAPE);
    end
end

