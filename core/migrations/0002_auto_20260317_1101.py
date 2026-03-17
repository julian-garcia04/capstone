# migrates the benchmark data to the DivisionBenchmark data table

from django.db import migrations
from django.core.management import call_command

def load_my_initial_data(apps, schema_editor):
    """
    This function is called when the migration is run.
    It runs the 'loaddata' command to load our benchmark fixture.
    """
    # The name of the fixture file, without the .json extension
    fixture_name = 'initial_benchmarks'
    call_command('loaddata', fixture_name)

def unload_my_initial_data(apps, schema_editor):
    """
    This function is called when the migration is "un-applied".
    It should remove the data that was loaded.
    """
    # We get the model from the 'apps' registry to ensure we have the
    # version of the model that matches this migration.
    DivisionBenchmark = apps.get_model('core', 'DivisionBenchmark')
    DivisionBenchmark.objects.all().delete()


class Migration(migrations.Migration):

    # This migration depends on the previous one that created the table
    dependencies = [
        ('core', '0001_initial'),
    ]

    # This is where we link our functions to the migration process
    operations = [
        migrations.RunPython(load_my_initial_data, reverse_code=unload_my_initial_data),
    ]