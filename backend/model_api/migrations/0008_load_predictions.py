# Generated by Django 3.0.4 on 2020-04-12 23:09

from django.db import migrations
from typing import List
import csv
import datetime
import _thread


class StaticModel:
    def __init__(self,
                 quarantined_prediction_paths: List[str],
                 name: str,
                 description: str = ""):
        self.quarantined_prediction_paths = quarantined_prediction_paths
        self.name = name
        self.description = description


STATIC_MODELS = [
    StaticModel(
        quarantined_prediction_paths=[
            "../results/forecasts/global_forecasts_current_0.csv",
            "../results/forecasts/us_forecasts_current_0.csv"
        ],
        name="SI-kJalpha - Default",
        description="The default version of the SI-kJalpha model, \
        the model calculates the under-reporting ratio based on the training data."
    ),
    StaticModel(
        quarantined_prediction_paths=[
            "../results/forecasts/global_forecasts_current_0_ub.csv",
            "../results/forecasts/us_forecasts_current_0_ub.csv"
        ],
        name="SI-kJalpha - Upper",
        description="The SI-kJalpha model forecating towards upper bounds, \
        the model calculates the under-reporting ratio based on the training data."
    ),
    StaticModel(
        quarantined_prediction_paths=[
            "../results/forecasts/global_forecasts_current_0_lb.csv",
            "../results/forecasts/us_forecasts_current_0_lb.csv"
        ],
        name="SI-kJalpha - Lower",
        description="The SI-kJalpha model forecating towards lower bounds, \
        the model calculates the under-reporting ratio based on the training data."
    )
]

STATIC_DEATH_MODELS = [
    StaticModel(
        quarantined_prediction_paths=[
            "../results/forecasts/global_deaths_current_0.csv",
            "../results/forecasts/us_deaths_current_0.csv"
        ],
        name="SI-kJalpha - Default (death prediction)",
        description="The default version of the SI-kJalpha model, \
        the model calculates the under-reporting ratio based on the training data."
    ),
    StaticModel(
        quarantined_prediction_paths=[
            "../results/forecasts/global_deaths_current_0_ub.csv",
            "../results/forecasts/us_deaths_current_0_ub.csv"
        ],
        name="SI-kJalpha - Upper (death prediction)",
        description="The SI-kJalpha model forecating towards upper bounds, \
        the model calculates the under-reporting ratio based on the training data."
    ),
    StaticModel(
        quarantined_prediction_paths=[
            "../results/forecasts/global_deaths_current_0_lb.csv",
            "../results/forecasts/us_deaths_current_0_lb.csv"
        ],
        name="SI-kJalpha - Lower (death prediction)",
        description="The SI-kJalpha model forecating towards lower bounds, \
        the model calculates the under-reporting ratio based on the training data."
    )
]


def load_csv(apps, path):
    """
    Reads the given CSV and returns a list of Covid19PredictionDataPoint
    objects. Only the date, area, and val fields on the objects are set. Note
    that the objects have not been saved into the database yet.
    :param apps: Django apps object.
    :param path: Path to CSV with prediction data.
    :return: List of Covid19PredictionDataPoint objects (NOT SAVED YET).
    """
    Area = apps.get_model('model_api', 'Area')
    Covid19PredictionDataPoint = apps.get_model(
        'model_api', 'Covid19PredictionDataPoint')

    with open(path, 'r') as f:
        reader = csv.reader(f)
        header = next(reader, None)

        data = []

        for row in reader:
            area = None

            # Determine the country / state.
            if 'global' in path:
                country = row[1]
                state = ''
            elif 'us' in path:
                country = 'US'
                state = row[1]
            else:
                msg = """Could not determine country/state from:
                                    row = %s
                                    path = %s""" % (str(row), path)
                raise RuntimeError(msg)

            # Try to find the corresponding area.
            try:
                area = Area.objects.get(country=country, state=state)
            except Area.DoesNotExist:
                msg = "Could not find the area for country '{0}'".format(
                    country)
                if state:
                    msg += " and state '{0}'".format(state)
                area = Area(state=state, country=country)
                area.save()
                msg += ' in model_api_area. New area created.'
                print(msg)

            except Area.MultipleObjectsReturned:
                msg = "Found multiple areas for country '{0}'".format(
                    country)
                if state:
                    msg += " and state '{0}'".format(state)
                msg += ' in model_api_area. Skip this area.'
                print(msg)
                continue

            # Load the predictions.
            for i in range(2, len(header)):
                date = header[i]

                # Skip invalid values.
                raw_val = row[i]
                if raw_val in ['NaN', '-Inf', 'Inf']:
                    continue

                # Skip negative values.
                val = int(float(raw_val))
                if val < 0:
                    continue

                data.append(Covid19PredictionDataPoint(
                    area=area,
                    date=date,
                    val=val,
                ))

        return data


def load_covid19_predictions(apps, schema_editor):
    Covid19InfectionModel = apps.get_model('model_api', 'Covid19InfectionModel')
    Covid19DeathModel = apps.get_model('model_api', 'Covid19DeathModel')

    print()
    for static_model in STATIC_MODELS:
        print("Loading model: " + static_model.name)

        # Create an entry for the model in the database.
        covid19_model = Covid19InfectionModel(
            name=static_model.name,
            description=static_model.description)
        covid19_model.save()

        # Load quarantined predictions.
        for path in static_model.quarantined_prediction_paths:
            new_predictions = load_csv(apps, path)
            # Update additional params and write to database.
            for p in new_predictions:
                p.model = covid19_model
                p.social_distancing = 1
                p.save()

    for static_model in STATIC_DEATH_MODELS:
        print("Loading model: " + static_model.name)

        # Create an entry for the model in the database.
        covid19_model = Covid19DeathModel(
            name=static_model.name,
            description=static_model.description)
        covid19_model.save()

        # Load quarantined predictions.
        for path in static_model.quarantined_prediction_paths:
            new_predictions = load_csv(apps, path)
            # Update additional params and write to database.
            for p in new_predictions:
                p.model = covid19_model
                p.social_distancing = 1
                p.save()


def delete_covid19_predictions(apps, schema_editor):
    Covid19PredictionDataPoint = apps.get_model(
        'model_api', 'Covid19PredictionDataPoint')
    Covid19Model = apps.get_model('model_api', 'Covid19Model')

    # Clear all prediction data points.
    Covid19PredictionDataPoint.objects.all().delete()
    # Clear all models.
    Covid19Model.objects.all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('model_api', '0007_covid19model_covid19predictiondatapoint'),
    ]

    operations = [
        migrations.RunPython(load_covid19_predictions,
                             delete_covid19_predictions)
    ]
