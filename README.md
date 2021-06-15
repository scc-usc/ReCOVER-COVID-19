<<<<<<< HEAD
# ReCOVER: Accurate Predictions and Resource Allocation for COVID-19 Epidemic Response

### Created by
Ajitesh Srivastava (ajiteshs@usc.edu)

### Code contributors

Ajitesh Srivastava, Frost Xu, Bob Xiaochen Yang, Jamin Chen

## Approach
We use our own epidemic model called [SI-kJalpha](https://arxiv.org/abs/2007.05180), preliminary version of which we have successfully used during [DARPA Grand Challenge 2014](https://news.usc.edu/83180/usc-engineers-earn-national-recognition-for-predicting-disease-outbreaks/). Our forecast appears on the official [CDC webpage](https://www.cdc.gov/coronavirus/2019-ncov/covid-data/forecasting-us.html).  Our model can consider the effect of many complexities of the epidemic process and yet be simplified to a few parameters that are learned using fast linear regressions. Therefore, our approach can learn and generate forecasts extremely quickly. On a 2 core desktop machine, our approach takes only 3.18s to tune hyper-parameters, learn parameters and generate 100 days of forecasts of reported cases and deaths for all the states in the US. The total execution time for 184 countries is 11.83s and for more than 3000 US counties is around 30s. For around 20,000 locations data for which are made available by [Google](https://github.com/GoogleCloudPlatform/covid-19-open-data), our approch takes around 10 mins.
Despite being fast, the accuracy of our forecasts is on par with the state-of-the-art as demonstrated on the [evaluation page](https://scc-usc.github.io/ReCOVER-COVID-19/#/leaderboard).

## Web Interface and Visualization
![](frontend/screenshot.png)
Our web-interface provides the following
1. [Our US state-level and global country-level forecasts here](https://scc-usc.github.io/ReCOVER-COVID-19/)
1. [Our forecasts for around 20,000 location covering Admin 0-2](https://scc-usc.github.io/ReCOVER-COVID-19/#/row)
1. [Weekly Highlights](https://scc-usc.github.io/ReCOVER-COVID-19/#/highlights)
1. [Comparison against other public forecasts](https://scc-usc.github.io/ReCOVER-COVID-19/#/leaderboard)


## Our papers
1. Full modeling details and comparisons: https://arxiv.org/abs/2007.05180
1. Identifying Unreported Cases; Accepted in [KDD 2020](https://www.kdd.org/kdd2020/calls/view/health-day-kdd-2020-ai-for-covid)): https://arxiv.org/abs/2006.02127
1. Initial Modeling: https://arxiv.org/abs/2004.11372

## Presentations/Seminars
1. Lightning talk presenting the status (October): https://www.youtube.com/watch?v=ll6k8wlxOFo
1. Webinar describing our intial approach (April): https://www.youtube.com/watch?v=dBye3euqlKc

## Acknowledgement

This work is supported by National Science Foundation Award No. 2027007 (RAPID).

PIs: Viktor K. Prasanna (prasanna@usc.edu), Ajitesh Srivastava (ajiteshs@usc.edu)
University of Southern California
=======
# Development

## Running Local Server
```
python manage.py runserver --settings=covid19_site.settings_dev
```

## Ingesting New Data
Optional One: Run the shell script ```migrate_data_scripts``` to fetch data from JHU's repository and update the predictions with the files within the ```forecasts``` folder. (MUST make sure the database structure and migration codes are not modified before running the command, otherwise unexpected results may show up.) 
```
.\migrate_data_scripts`
```
&nbsp;

Optional Two: Manually reset the database and re-migrate the code.
Delete all previously-existing data (ideally we would not have to do this step 
but it's just more robust given that JHU recently changed the areas they had
in their data).
```
python manage.py dbshell
> .tables // lists all tables
> DROP TABLE model_api_area;
> DROP TABLE model_api_covid19cumulativedatapoint;
> DROP TABLE model_api_covid19datapoint;
> DROP TABLE model_api_covid19deathdatapoint;
> DROP TABLE model_api_covid19deathmodel;
> DROP TABLE model_api_covid19infectionmodel;
> DROP TABLE model_api_covid19model;
> DROP TABLE model_api_covid19predictiondatapoint;
> DROP TABLE model_api_quarantinescoredatapoint;
> .quit
```
Now we need to fake back to migration state 0 so that Django can rerun all the 
migrations.
```
python manage.py migrate model_api zero --fake
```
Now Django thinks we're at the state before we ran all migrations, so we can
simply rerun them to load the newest data to our database.
```
python manage.py migrate
```

## Deploying
```
git subtree push --prefix backend heroku master
```
>>>>>>> 67fa49eea5d682e9d3eb569e07d9d13adaeccb83
