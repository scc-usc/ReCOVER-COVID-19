from django.urls import path
from model_api import views


urlpatterns = [
    path('areas/', views.areas),
]
