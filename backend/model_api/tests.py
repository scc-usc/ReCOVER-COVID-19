from django.test import TestCase
from django.apps import apps
from model_api import views

from parameterized import parameterized

# Create your tests here.
class MigrationTestCase(TestCase):
    # Test if all predcitions models are loaded during migration.
    @parameterized.expand([
        ("SI-kJalpha - Default"),
        ("SI-kJalpha - Default (death prediction)"),
        ("SI-kJalpha - Upper"),
        ("SI-kJalpha - Lower"),
        ("SI-kJalpha - Upper (death prediction)"),
        ("SI-kJalpha - Lower (death prediction)"),
    ])
    def test_load_prediction_models(self, model_name):
        Covid19Model = apps.get_model('model_api', 'Covid19Model')
        model = Covid19Model.objects.get(name=model_name)
        self.assertIsNotNone(model)
        self.assertEqual(model.name, model_name)
