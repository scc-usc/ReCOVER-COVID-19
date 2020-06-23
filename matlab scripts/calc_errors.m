function [meanMSE, meanMAPE, allMSE, allMAPE] = calc_errors(gtruth, predvals)
    %Calculates RMSE and Symmetric MAPE for forecasts
    allMSE = sum((gtruth-predvals).^2, 2);
    meanMSE = sqrt(nanmean(allMSE));
    allMAPE = sum(abs(gtruth-predvals)./(0.5*gtruth+0.5*predvals+ 1e-5), 2);
    meanMAPE = nanmean(allMAPE);
end

