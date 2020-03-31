from django.db import models

# Create your models here.


class Area(models.Model):
    state = models.CharField(max_length=50)
    country = models.CharField(max_length=50)
    iso_2 = models.CharField(max_length=10, default="")
    lat = models.FloatField()
    long = models.FloatField()

    class Meta:
        unique_together = ("state", "country")

    def __str__(self):
        area_str = self.country
        if self.state:
            area_str += " - " + self.state
        return area_str


class Covid19DataPoint(models.Model):
    area = models.ForeignKey(Area, on_delete=models.CASCADE)
    date = models.DateField()
    val = models.PositiveIntegerField()

    def __str__(self):
        return str(self.area) + ", " + str(self.date) + ", " + str(self.val)


class Covid19CumulativeDataPoint(models.Model):
    area = models.ForeignKey(Area, on_delete=models.CASCADE)
    data_point = models.ForeignKey(Covid19DataPoint, on_delete=models.CASCADE)

    def __str__(self):
        return str(self.area) + ", " + str(self.data_point)
