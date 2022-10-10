function [IC,t_prime] = future_IC(all_data_vars2,age_groups,abvs,hk,now_date)
t_prime = -ones(length(abvs),length(age_groups));
IC = nan(length(abvs),(hk)*7,length(age_groups));

flag = 0;
all_data_vars2 = smoothdata(all_data_vars2,3,'movmean',14);
for st = 1:56
    for g=1:5
        this_series = squeeze(all_data_vars2(st,1,:,g));
        [~, max_t] = max(this_series);
        this_series1 = cumsum(this_series(1:max_t)); this_series1 = diff(this_series1(1:8:end));
        this_series1(this_series1< 1e-20) = Inf;
        min_thres = min(this_series1);

        for t=15:max_t
            if any(isnan(this_series1))
                continue;
            end


            %Case where we find no replacement
            if t+14 > max_t
                IC(st,:,g) = (min_thres/14);
                t_prime(st,g) = 0; %(t > t, so insertion happens immediately)
                break;
            end
            temp_dat = this_series(t-6:t+14);%squeeze(all_data_vars2(st,1,t-27:t,g));%
            %                 temp_dat = smoothdata(temp_dat,3,'movmean',7);
            td = temp_dat(1:7);
            if sum(temp_dat(1:7))<= (min_thres+ 1e-3) && (td(1)-td(7) < 0) && ~flag
                flag =1;
                d = days(now_date - (datetime(2021, 9, 1) + days(t)));
                continue;
            end
            if flag && nansum(temp_dat(end-13:end-7),'all')>(min_thres+ 1e-3) && nansum(temp_dat(end-6:end),'all')>(min_thres+ 1e-3) && (td(end)-td(1) > 0)
                td = smoothdata(all_data_vars2(st,1,t:t+13,g),3,'movmean',7);
                IC(st,:,g)=td(:,:,1:14,:);
                d = days(now_date - (datetime(2021, 9, 1) + days(t)));
                t_prime(st,g) = t + 18; %This would be where to insert since old data starts sep1st (18days after aug14th)
                flag = 0;
                break;
            end
        end
    end
end

for g = 1:5
    bad_idx = t_prime(:, g) < 1;
    t_prime(bad_idx, g) = round(median(t_prime(~bad_idx, g))+0.5);
end
end

