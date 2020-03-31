from rest_framework.decorators import api_view
from rest_framework.exceptions import APIException
from rest_framework.response import Response
from model_api.models import Area, Covid19DataPoint

SOURCE_PREDICTED_STR = "predicted"
SOURCE_OBSERVED_STR = "observed"


@api_view(["GET"])
def affected_by(request):
    return Response("affected_by!")


@api_view(["GET"])
def areas(request):
    """
    This endpoint returns a list of all areas we have observed data for.
    """
    all_areas = [{
        'country': a.country,
        'state': a.state,
        'lat': a.lat,
        'long': a.long} for a in Area.objects.all()]
    return Response(all_areas)


@api_view(["GET"])
def cumulative_infections(request):
    """
    This endpoint returns the number of cumulative infections for each area to
    date.
    """


@api_view(["GET"])
def predict(request):
    """
    This endpoint handles predicting the data for a specific area. The expected
    query params are "country" and "state," and the response is a list of data
    points, each represented as custom objects containing the date of infection,
    the value, and source (a string indicating whether this data point was
    predicted by our model or is from observed data).
    """
    country = request.query_params.get("country")
    state = request.query_params.get("state")

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

    response = []

    query_set = Covid19DataPoint.objects.filter(area=area)
    for d in query_set:
        response.append({
            "date": d.date,
            "value": d.val,
            "source": SOURCE_OBSERVED_STR,
        })

    return Response(response)
