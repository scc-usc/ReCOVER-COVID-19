from django.urls import path
from model_api import views


urlpatterns = [
    path('affected_by/', views.affected_by),
    path('areas/', views.areas),
    path('cumulative_infections/', views.cumulative_infections),
    path('predict/', views.predict),
    path('models/', views.models)
]
