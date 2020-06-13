from django.urls import path
from model_api import views


urlpatterns = [
    path('affected_by/', views.affected_by),
    path('areas/', views.areas),
    path('cumulative_infections/', views.cumulative_infections),
    path('predict/', views.predict),
    path('predict_all/', views.predict_all),
    path('models/', views.models),
    path('infection_models/', views.infection_models),
    path('death_models/', views.death_models),
    path('current_date/', views.getCurrentDate),
    path('scores/', views.scores),
    path('scores_all/', views.scores_all),
    path('check_history/', views.check_history),
    path('history_cumulative/', views.history_cumulative),
    path('latest_score_date/', views.latest_score_date)
]