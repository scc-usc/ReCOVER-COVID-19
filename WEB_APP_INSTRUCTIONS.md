# Instructions to build and deploy the web app

## Preparation: Install software, packages and environment for the project.
0. Make sure MATLAB® and Python (Python3 is encouraged) are installed.
1. Navigate to the `backend/` folder. Install required Python packages by running the the script:
    ```
    pip3 install -r requirements.txt
    ```
2. Install the frontend tool [yarn](https://classic.yarnpkg.com/en/docs/install/#mac-stable).
3. Navigate to the `frontend/` folder. Install required packages and dependencies by running the the script:
    ```
    yarn install
    ```
4. Install [heroku](https://devcenter.heroku.com/articles/heroku-cli) (If you want to contribute to the backend but you are not a collaborator of our heroku project yet, please contact the current collaborator.).

## Data updates: Update forecasts, reproduction number, and leaderboards.

### MATLAB®
Navigate to the `matlab scripts/` directory. Generate the forecasts and reproduction number by running following matlab scripts on MATLAB®:

1. Run `daily_run.m`, this script will generate global and US-state level cumulative infections and deaths forecasts under `ReCOVER-COVID-19/results/forecasts/` directory.

2. Generate country-level reproduction number: 
    1. Load `hyper_params/global_hyperparam_ref_xxx.mat`. 
    2. Run `load_data_global.m`. 
    3. Edit the file `generate_scores.m` on line 5 and 6:
        ```
        %prefix = 'us'; % Comment out this line.
        prefix = 'global'; % Uncomment this line.
        ```
    3. Run `generate_scores.m` to generate country-level reproduction numbers.

3. Generate US state-level reproduction number: 
    1. Load `hyper_params/us_hyperparam_ref_xxx.mat`. 
    2. Run `load_data_us.m`.
    3. Edit the file `generate_scores.m` on line 5 and 6:
        ```
        prefix = 'us'; % Uncomment this line.
        %prefix = 'global'; % Comment out this line.
        ```
    4. Run `generate_scores.m` to generate us state-level reproduction numbers.


    Both global and US reproduction number files will be generated under `ReCOVER-COVID-19/results/scores/` directory.


### Backend
Navigate to the `/backend` directory, migrate the new forecasts and reproduction number to the local database:

0. If you have modified any backend database schema or migration logics, please read the `README.md` under the `backend` directory and perform a manual migrate. Otherwise this is intended to be a normal data update, you may follow this instruction.

1. Run the script:
    ```
    bash ./migrate_data_scripts
    ```
2. Run the server locally:
    ```
    python manage.py runserver --settings=covid19_site.settings_dev
    ```

### Frontend 
The leaderboard page needs to be updated manually every week. It is usually updated on every Monday. Navigate to the `frontend` directory.

1. Edit `src/leaderboard/leaderboard.js`, change the `data` varaible.
2. Update the graphs in `src/leaderboard/img`, the new images should have exactly the name `jhu_graph.png`, `nyt_graph.png`, `usf_graph.png`, or `all_graph.png`.
3. Run the following script to run the web page on `localhost:3000/ReCOVER-COVID-19`
    ```
    yarn start
    ```

After the backend server and frontend page has been running locally. Please examine if there are any bugs before deploying.

## Deployment: Deploy the updates to the public website.
1. Push your commits to the GitHub repository.

2. Navigate to `backend/` directory, run the following script to deploy backend changes to the heroku servers:
    ```
    git subtree push --prefix backend heroku master
    ```

    3. Navigate to `frontend/` directory, run the following script  to deploy frontend changes:
    ```
    yarn deploy
    ```