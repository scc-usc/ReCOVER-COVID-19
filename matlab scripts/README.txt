# Forecasting

To generate forecasts, run
daily_run.m


Equivalently, you can also run the following scripts:

1. load corresponding *_hyperparam_ref_64 file. This loads hyperparameters that are used to learn models at reference day. "64" can be replaced with 50, 57, 64, 71, ...
--- generate_scores.m has been included to generate reproduction unmbers over the week. In the process it also computes hyper_parameters over time.
2. load_data_*.m : Run the appropriate file us/global. This will load data from JHU githb
3. hyperparam_tuning.m: If you want, you can change the validation and test size in the first block. Default is 4 and 4.
4. varying_test.m: This will generate all the results in csv files. Update the file_prefix and horizon is needed in the first block
5. write_data_*.m: Run the appropriate file us/global. This will generate the forecast files in the right format


Two crucial functions that learn and apply the epidemic model:
- var_ind_beta_un.m: Learns the linearized version using linear least square minimization
- var_simulate_pred_un.m: Applies the paramaters to predict following the currently know data

--------------
Population data , travel data, and country names are included here

Also included is a live script: plot_gen.mlx to visualize forecasts instead of writing forecasts in files.

# Unreported Cases

To test the code for estimation of unreported cases, use the live script: daily_explore_unrep.mlx
