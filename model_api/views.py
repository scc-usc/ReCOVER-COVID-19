from rest_framework.decorators import api_view
from rest_framework.response import Response
from model_api.models import Area
from django.http import JsonResponse
from django.shortcuts import render

# Create your views here.


@api_view(["GET"])
def areas(request):
    all_areas = [{'country': a.country, 'state': a.state} for a in Area.objects.all()]
    return Response(all_areas)
