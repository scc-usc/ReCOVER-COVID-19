from django.contrib import admin
from .models import Area, Covid19DataPoint, Covid19CumulativeDataPoint, Covid19QuarantinePredictionDataPoint, Covid19ReleasedPredictionDataPoint

# Register your models here.

admin.site.register(Area)
admin.site.register(Covid19DataPoint)
admin.site.register(Covid19CumulativeDataPoint)
admin.site.register(Covid19QuarantinePredictionDataPoint)
admin.site.register(Covid19ReleasedPredictionDataPoint)