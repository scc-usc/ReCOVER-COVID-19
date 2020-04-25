To generate forecasts, run the following scripts

1. load corresponding *March18_hyperparams file. This loads hyperparameters that are used to learn models at reference day
--- hyperparam_reference.m has been included to geenrate the relevant data for any reference day.
2. load_data_*.m : Run the appropriate file us/global. This will load data from JHU githb
3. hyperparam_tuning.m: If you want, you can change the validation and test size in the first block. Default is 4 and 4.
4. varying_test.m: This will generate all the results in csv files. Update the file_prefix and horizon is needed in the first block
5. write_data_*.m: Run the appropriate file us/global. This will generate the forecast files in the right format

---------------
Example scripts:
load_data_us hyperparam_tuning; varying_test; write_data_us

load_data_global; hyperparam_tuning; varying_test; write_data_global
---------------

Two crucial functions that learn and apply the epidemic model:
- var_ind_beta.m: Learns the linearized version using linear least square minimization
- var_simulate_pred.m: Applies the paramaters to predict following the currently know data

--------------
Population data , travel data, and country names are included here
