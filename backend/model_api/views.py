from rest_framework.decorators import api_view
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from datetime import timedelta, datetime, date
from model_api.models import \
    Area, \
    Covid19DataPoint, \
    Covid19CumulativeDataPoint, \
    Covid19Model, \
    Covid19InfectionModel, \
    Covid19DeathModel, \
    Covid19PredictionDataPoint, \
    Covid19DeathDataPoint, \
    QuarantineScoreDataPoint, \
    MRFScoreDataPoint

@api_view(["GET"])
def affected_by(request):
    return Response("affected_by!")

@api_view(["GET"])
def getCurrentDate(request):
    """
    This endpoint returns the date of the most recent cumulative data of observed data
    """
    # observed = Covid19DataPoint.objects.filter(
    #     area=Area.objects.get(country="US", state="")
    # )
    currentDate = Covid19DataPoint.objects.last().date
    firstDate = Covid19DataPoint.objects.first().date
    date = [{
        'date': currentDate,
        'firstDate': firstDate
        }]
    return Response(date)


@api_view(["GET"])
def areas(request):
    """
    This endpoint returns a list of all areas we have observed data for.
    """
    all_areas = [{
        'country': a.country,
        'state': a.state,
        'iso_2': a.iso_2, } for a in Area.objects.all()]
    return Response(all_areas)


@api_view(["GET"])
def cumulative_infections(request):
    """
    This endpoint returns the number of cumulative infections for each area to
    date.
    """
    lastDate = Covid19DeathDataPoint.objects.last().date
    response = [{
        'area': {
            'country': d.area.country,
            'state': d.area.state,
            'iso_2': d.area.iso_2,
        },
        'value': d.data_point.val,
        'date': d.data_point.date,
    } for d in Covid19CumulativeDataPoint.objects.all()]


    return Response(response)

@api_view(['GET'])
def cumulative_death(request):
    days = int(request.query_params.get("days"))
    lastDate = Covid19DeathDataPoint.objects.last().date
    historyDate = lastDate - timedelta(days=-days)
    return Response([{
        'area': {
            'country': m.area.country,
            'state': m.area.state,
            'iso_2': m.area.iso_2,
        },
        'value': m.val,
        'date': m.date
    } for m in Covid19DeathDataPoint.objects.filter(date=historyDate)])

@api_view(["GET"])
def models(request):
    return Response([{
        'name': m.name,
        'description': m.description
    } for m in Covid19Model.objects.all()])


@api_view(["GET"])
def infection_models(request):
    return Response([{
        'name': m.name,
        'description': m.description
    } for m in Covid19InfectionModel.objects.all()])


@api_view(["GET"])
def death_models(request):
    return Response([{
        'name': m.name,
        'description': m.description
    } for m in Covid19DeathModel.objects.all()])


@api_view(["GET"])
def predict(request):
    """
    This endpoint handles predicting the data for a specific area over some number
    of days in the future. The expected query params are "country", "state" and "days", 
    and the response is a list of data points, each represented as custom objects containing 
    the date of infection, the value, and source (a string indicating whether this data point was
    predicted by our model or is from observed data) in a given number of future days.
    """
    country = request.query_params.get("country")
    state = request.query_params.get("state")
    days = int(request.query_params.get("days"))

    true_vals = ['True', 'true']
    current = request.query_params.get("current", None) in true_vals
    worst_effort = request.query_params.get("worst_effort", None) in true_vals
    best_effort = request.query_params.get("best_effort", None) in true_vals

    # Get the models from the URl query parameters.
    # Django expects it to be of the form: 'models=foo&models=bar&...'
    models = request.GET.getlist("models[]", [])

    # Get the area and raise an API exception if we can't.
    try:
        area = Area.objects.get(country=country, state=state)
    except Area.DoesNotExist:
        msg = "Could not find the area for country '{0}'".format(country)
        if state:
            msg += " and state '{0}'".format(state)
        raise APIException(msg)
    except Area.MultipleObjectsReturned:
        msg = "Found multiple areas for country '{0}'".format(country)
        if state:
            msg += " and state '{0}'".format(state)
        msg += ". This is most likely an error with data cleansing."
        raise APIException(msg)

    response = {
        "observed": [],
        "predictions": [],
        "observed_deaths": [],
    }

    # Pull observed data from database.
    observed = Covid19DataPoint.objects.filter(area=area)
    for d in observed:
        response["observed"].append({
            "date": d.date,
            "value": d.val,
        })

    observed_deaths = Covid19DeathDataPoint.objects.filter(area=area)
    for d in observed_deaths:
        response["observed_deaths"].append({
            "date": d.date,
            "value": d.val,
        })

    # Determine the time range for predictions.
    prediction_start_date = max([d.date for d in observed]) + timedelta(days=1)
    prediction_end_date = prediction_start_date + timedelta(days=days)

    for model_name in models:
        model = Covid19Model.objects.get(name=model_name)
        model_death = None
        if model_name[:10] == "SI-kJalpha":
            print(model_name + " (death prediction)")
            model_death = Covid19Model.objects.get(name=model_name + " (death prediction)")
        if current:
            qs = Covid19PredictionDataPoint.objects.filter(
                model=model,
                social_distancing=1,
                area=area,
                date__range=(prediction_start_date, prediction_end_date)
            )

            if model_death:
                qs_death = Covid19PredictionDataPoint.objects.filter(
                        model=model_death,
                        social_distancing=1,
                        area=area,
                        date__range=(prediction_start_date, prediction_end_date)
                )

            response["predictions"].append({
                "model": {
                    "name": model.name,
                    "description": model.description
                },
                "distancing": "current",
                "time_series": [{
                    "date": d.date,
                    "value": d.val,
                } for d in qs]
            })

            if model_death:
                response["predictions"].append({
                    "model": {
                        "name": model_death.name,
                        "description": model_death.description
                    },
                    "distancing": "current",
                    "time_series": [{
                        "date": d.date,
                        "value": d.val,
                    } for d in qs_death]
                })

        if worst_effort:
            qs = Covid19PredictionDataPoint.objects.filter(
                model=model,
                social_distancing=0,
                area=area,
                date__range=(prediction_start_date, prediction_end_date)
            )

            if model_death:
                qs_death = Covid19PredictionDataPoint.objects.filter(
                    model=model_death,
                    social_distancing=0,
                    area=area,
                    date__range=(prediction_start_date, prediction_end_date)
                )

            response["predictions"].append({
                "model": {
                    "name": model.name,
                    "description": model.description
                },
                "distancing": "worst_effort",
                "time_series": [{
                    "date": d.date,
                    "value": d.val,
                } for d in qs]
            })

            if model_death:
                response["predictions"].append({
                    "model": {
                        "name": model_death.name,
                        "description": model_death.description
                    },
                    "distancing": "worst_effort",
                    "time_series": [{
                        "date": d.date,
                        "value": d.val,
                    } for d in qs_death]
                })

        if best_effort:
            qs = Covid19PredictionDataPoint.objects.filter(
                model=model,
                social_distancing=2,
                area=area,
                date__range=(prediction_start_date, prediction_end_date)
            )

            if model_death:
                qs_death = Covid19PredictionDataPoint.objects.filter(
                    model=model_death,
                    social_distancing=2,
                    area=area,
                    date__range=(prediction_start_date, prediction_end_date)
                )

            response["predictions"].append({
                "model": {
                    "name": model.name,
                    "description": model.description
                },
                "distancing": "best_effort",
                "time_series": [{
                    "date": d.date,
                    "value": d.val,
                } for d in qs]
            })

            if model_death:
                response["predictions"].append({
                    "model": {
                        "name": model_death.name,
                        "description": model_death.description
                    },
                    "distancing": "best_effort",
                    "time_series": [{
                        "date": d.date,
                        "value": d.val,
                    } for d in qs_death]
                })


    return Response(response)


@api_view(["GET"])
def check_history(request):
    """
    return the data for a region in a certain time in history
    """
    country = request.query_params.get("country")
    state = request.query_params.get("state")
    #days should be negative
    days = int(request.query_params.get("days"))
    try:
        area = Area.objects.get(country=country, state=state)
    except Area.DoesNotExist:
        msg = "Could not find the area for country '{0}'".format(country)
        if state:
            msg += " and state '{0}'".format(state)
        raise APIException(msg)
    except Area.MultipleObjectsReturned:
        msg = "Found multiple areas for country '{0}'".format(country)
        if state:
            msg += " and state '{0}'".format(state)
        msg += ". This is most likely an error with data cleansing."
        raise APIException(msg)

    #currentDate = max([d.date for d in observed])
    response = {
        "observed": [],
        "predictions": [],
        "observed_deaths": [],
    }
    observed = Covid19DataPoint.objects.filter(area=area)
    currentDate = max([d.date for d in observed])
    lastShownDate = currentDate - timedelta(days=-days)
    shown = observed.filter(date__lte=lastShownDate)
    for d in shown:
        response["observed"].append({
            "date": d.date,
            "value": d.val,
        })

    observed_deaths = Covid19DeathDataPoint.objects.filter(
        area = area,
        date__lte=lastShownDate
    )

    for d in observed_deaths:
        response["observed_deaths"].append({
            "date": d.date,
            "value": d.val,
        })

    return Response(response)


@api_view(["GET"])
def predict_all(request):
    days = int(request.query_params.get("days"))
    model_name = request.query_params.get("model")

    # We need to find the last date of the observed data.
    observed = Covid19DataPoint.objects.filter(
        area=Area.objects.get(country="US", state="")
    )
    date = max([d.date for d in observed]) + timedelta(days=days)
    model = Covid19Model.objects.get(name=model_name)

    qs = Covid19PredictionDataPoint.objects.filter(model=model, date=date)

    response = [{
        'area': {
            'country': d.area.country,
            'state': d.area.state,
            'iso_2': d.area.iso_2,
        },
        'value': d.val,
        'date': d.date,
    } for d in qs]

    return Response(response)

@api_view(["GET"])
def scores(request):
    """
    This endpoint will return a list of quarantine score data points of 
    for a specific area from 2020-3-11 to a given date. The expected 
    query params are "country", "state" and "weeks" where "weeks" denoting 
    the number of weeks after 2020-3-11.
    """
    country = request.query_params.get("country")
    state = request.query_params.get("state")
    weeks = int(float(request.query_params.get("weeks")))

    # Get the area and raise an API exception if we can't.
    try:
        area = Area.objects.get(country=country, state=state)
    except Area.DoesNotExist:
        msg = "Could not find the area for country '{0}'".format(country)
        if state:
            msg += " and state '{0}'".format(state)
        raise APIException(msg)
    except Area.MultipleObjectsReturned:
        msg = "Found multiple areas for country '{0}'".format(country)
        if state:
            msg += " and state '{0}'".format(state)
        msg += ". This is most likely an error with data cleansing."
        raise APIException(msg)

    response = {
        "observed_rt": [],
        "observed_mrf": []

    }

    score_start_date = QuarantineScoreDataPoint.objects.first().date
    score_end_date = score_start_date + timedelta(days=7*weeks)

    quarantine_scores = QuarantineScoreDataPoint.objects.filter(
        area=area,
        #date__range=(score_start_date, score_end_date)
        date__lte=score_end_date
    )
    for d in quarantine_scores:
        response["observed_rt"].append({
            "date": d.date,
            "value": d.val,
            "conf": d.conf
        })

    mrf_scores = MRFScoreDataPoint.objects.filter(
        area=area,
    )
    for d in mrf_scores:
        response["observed_mrf"].append({
            "date":d.date,
            "value":d.val,
            "conf":d.conf
        })

    return Response(response)

@api_view(["GET"])
def scores_all(request):
    """
    This endpoint will return a list of quarantine score data points 
    for all areas in a given date. The query param contains "weeks" and 
    "weeks" denote the number of weeks after 2020-3-11.
    """
    weeks = int(float(request.query_params.get("weeks")))
    score_start_date = QuarantineScoreDataPoint.objects.first().date
    date = score_start_date + timedelta(days=7*weeks)

    quarantine_scores = QuarantineScoreDataPoint.objects.filter(
        date=date
    )

    response = [{
        'area': {
            'country': d.area.country,
            'state': d.area.state,
            'iso_2': d.area.iso_2,
        },
        'value': d.val,
        'date': d.date,
        'conf': d.conf

    } for d in quarantine_scores]
    
    return Response(response)

@api_view(['GET'])
def latest_score_date(request):
    """
    return the last date which the QuarantineScore data is aviliable (also returns first date)
    """
    latest_date = QuarantineScoreDataPoint.objects.last().date
    date2 = QuarantineScoreDataPoint.objects.first().date
    delta = latest_date - date2
    response = [{
        'date': latest_date,
        'weeks': delta.days/7,
        'firstDate': date2
    }]
    return Response(response)


@api_view(['GET'])
def all_mrf_scores(request):
    """
        This endpoint will return a list of quarantine score data points
        for all areas in a given date. The query param contains "weeks" and
        "weeks" denote the number of weeks after 2020-3-11.
    """
    weeks = int(float(request.query_params.get("weeks")))
    firstDate = MRFScoreDataPoint.objects.first().date
    date = firstDate + timedelta(days=7 * weeks)

    mrf_scores = MRFScoreDataPoint.objects.filter(
        date=date
    )

    response = [{
        'area': {
            'country': d.area.country,
            'state': d.area.state,
            'iso_2': d.area.iso_2,
        },
        'value': d.val,
        'date': d.date,
        'conf': d.conf

    } for d in mrf_scores]

    return Response(response)

@api_view(["GET"])
def history_cumulative(request):
    """
    This endpoints returns the number of cumulative infections for each area given a date in history.
    """
    days = int(request.query_params.get("days"))
    observed = Covid19DataPoint.objects.all()
    historyDate = max([d.date for d in observed]) - timedelta(days=-days)
    shownData = observed.filter(date=historyDate)
    deathData = Covid19DeathDataPoint.objects.filter(date=historyDate)
    response = [{
        'area': {
            'country': d.area.country,
            'state': d.area.state,
            'iso_2': d.area.iso_2,
        },
        'value': d.val,
        'date': d.date,
        'deathValue': deathData.filter(area=d.area, date=d.date).first().val
    } for d in shownData]

    return Response(response)
