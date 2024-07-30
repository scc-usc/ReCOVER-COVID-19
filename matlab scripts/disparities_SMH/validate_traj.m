function [sidx, errs] = validate_traj(sims, gt)
%VALIDATE_TRAJ Summary of this function goes here
%   Detailed explanation goes here
numsim = size(sims, 1);
ns = size(sims, 2);
errs = zeros(numsim, ns);
sidx = zeros(numsim, ns);

maxt = min([size(sims, 3), size(gt, 2)]);
if length(size(gt)) == 2
    sims = sims(:, :, 1:maxt);
    gt = gt(:, 1:maxt);
elseif length(size(gt)) == 3
    sims = sims(:, :,1:maxt, :);
    gt = gt(:, 1:maxt, :);
end
   
for cid = 1:ns
for j=1:numsim
    if length(size(gt)) == 3
        this_sim = sims(j, cid, :, :); this_gt = gt(cid, :, :);
    elseif length(size(gt)) == 2
        this_sim = sims(j, cid, :); this_gt = gt(cid, :);
    end
    errs(j, cid) = sum((squeeze(this_sim) - this_gt).^2, 'all');
end
[~, sidx(:, cid)] = sort(errs(:, cid), 'ascend');
end
end

