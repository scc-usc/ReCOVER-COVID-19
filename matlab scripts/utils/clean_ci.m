function ci_out = clean_ci(ci, bounds)
%Cleans the confidence interval ci (2x1 matrix)output to remove nan entries and replace
%with the default provided as bounds [lb, ub]
lb = bounds(1, 1);
ub = bounds(1, 2);
ci_out = [lb ub];

if isnan(ci(1))
    ci(1) = lb;
end
if isnan(ci(2))
    ci(2) = ub;
end

ci_out = [max(ci(1), lb) min(ci(2), ub)];

end

