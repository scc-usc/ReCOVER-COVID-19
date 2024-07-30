function [C] = prod_2w3(A,B)
%PROD_2W3: pointwise product of A(mxk) and B(mxnxk) matrix
C = B;

if length(size(B)) == 3
    for tt = 1:size(B, 2)
        C(:, tt, :) = squeeze(B(:, tt, :)).*A;
    end
else
    C = A.*B;
end

