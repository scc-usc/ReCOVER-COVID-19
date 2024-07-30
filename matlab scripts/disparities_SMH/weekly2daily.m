function [newData] = weekly2daily(data)
    % Dimensions of the data
    [dim1, weeks, dim3] = size(data);
    
    % Original weekly time points
    originalTime = 1:7:7*weeks;  % Assuming each point is 7 days apart
    
    % New daily time points
    newTime = 1:7*weeks;  % Daily points over the same period
    
    % Initialize the new data array with daily time points
    newData = zeros(dim1, length(newTime), dim3);
    
    % Perform the interpolation for each slice of the matrix
    for i = 1:dim1
        for j = 1:dim3
            % Extract the data for the current slice
            currentData = squeeze(data(i, :, j));
            
            % Perform interpolation
            interpolatedData = interp1(originalTime, currentData, newTime, 'cubic');
            interpolatedData(interpolatedData<0) = 0;
            % Assign the interpolated data back to the new array
            newData(i, :, j) = interpolatedData;
        end
    end
end