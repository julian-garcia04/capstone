# migrates benchmark data to the DivisionBenchmark datatable

from django.db import migrations
from django.core.management import call_command

def load_my_initial_data(apps, schema_editor):
    fixture_name = 'initial_benchmarks'
    call_command('loaddata', fixture_name)

def unload_my_initial_data(apps, schema_editor):
    DivisionBenchmark = apps.get_model('core', 'DivisionBenchmark')
    DivisionBenchmark.objects.all().delete()

class Migration(migrations.Migration):
    dependencies = [
        ('core', '0001_initial'),
    ]
    operations = [
        migrations.RunPython(load_my_initial_data, reverse_code=unload_my_initial_data),
    ]