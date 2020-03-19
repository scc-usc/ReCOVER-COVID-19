from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.http import JsonResponse
from django.shortcuts import render

# Create your views here.


@api_view(["GET"])
def countries(request):
    return Response({"message": "Hello, world!"})
