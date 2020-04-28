# Development

## Running Local Server
```
python manage.py runserver --settings=covid19_site.settings_dev
```

## Ingesting New Data

Delete all previously-existing data (ideally we would not have to do this step 
but it's just more robust given that JHU recently changed the areas they had
in their data).
```
python manage.py dbshell
> .tables // lists all tables
> DROP TABLE model_api_area;
> DROP TABLE model_api_covid19datapoint;
> DROP TABLE model_api_covid19cumulativedatapoint;
> DROP TABLE model_api_covid19quarantinepredictiondatapoint;
> DROP TABLE model_api_covid19releasedpredictiondatapoint;
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

#Deploying
```
git subtree push --prefix backend heroku master
```
