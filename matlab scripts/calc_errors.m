function [meanMSE, meanMAPE, allMSE, allMAPE] = calc_errors(gtruth, predvals)
    %Calculates MSE and Symmetric MAPE for forecasts
    allMSE = sum((gtruth-predvals).^2, 2);
    meanMSE = mean(allMSE);
    allMAPE = sum(abs(gtruth-predvals)./(0.5*gtruth+0.5*predvals+ 1e-10), 2);
    meanMAPE = mean(allMAPE);
end

