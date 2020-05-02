from django.db import models

# Create your models here.


class Area(models.Model):
    state = models.CharField(max_length=50)
    country = models.CharField(max_length=50)
    # Blank default value for iso_2 because this field was added later (after
    # the Area model was already created).
    iso_2 = models.CharField(max_length=10, default="")

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


class Covid19Model(models.Model):
    name = models.CharField(max_length=50)

    def __str__(self):
        return self.name


class Covid19PredictionDataPoint(models.Model):
    model = models.ForeignKey(Covid19Model, on_delete=models.CASCADE)
    area = models.ForeignKey(Area, on_delete=models.CASCADE)
    date = models.DateField()
    val = models.PositiveIntegerField()

    def __str__(self):
        return ",".join([str(x) for x in [
            self.model,
            self.area,
            self.date,
            self.val]])
