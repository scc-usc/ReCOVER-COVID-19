function [hosp_cumu_s_old] = select_old(hosp_dat_old,thisday,season)
    data_4_old = squeeze(hosp_dat_old(size(hosp_dat_old,1)-season+1,:,:,:));
    hosp_cumu_old = cumsum(data_4_old,2,'omitnan');%hosp_cumu(:, 1:min([thisday size(hosp_cumu, 2)]));
    hosp_cumu_s_old = nan(size(hosp_cumu_old));
    for i = 1:size(hosp_cumu_old,3)
        hosp_cumu_s_old(:,:,i) = smooth_epidata(squeeze(hosp_cumu_old(:,:,i)), 14, 0, 1); %smooth_epidata(data_4, smooth_factor/2, 1, 1);
    end
end

