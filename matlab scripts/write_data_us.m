%% Write forecasts
file_prefix = 'us';
%file_suffix = num2str(un); % Factor for unreported cases
file_suffix = ''; % Factor for unreported cases

lowidx = data_4(:, 60) < 50; % Note the regions with unreliable data on reference day

writetable(infec2table(infec, countries), [file_prefix '_forecasts_quarantine_' file_suffix '.csv']);
writetable(infec2table(infec_f, countries), [file_prefix '_forecasts_quarantine1_' file_suffix '.csv']);
writetable(infec2table(0.5*(infec_f+infec), countries), [file_prefix '_forecasts_quarantine_avg_' file_suffix '.csv']);
writetable(infec2table(infec_released, countries, lowidx), [file_prefix '_forecasts_released_' file_suffix '.csv']);
writetable(infec2table(infec_released_f, countries, lowidx), [file_prefix '_forecasts_released1_' file_suffix '.csv']);
writetable(infec2table(0.5*(infec_released+infec_released_f), countries, lowidx), [file_prefix '_forecasts_released_avg_' file_suffix '.csv']);

disp('Files written');
