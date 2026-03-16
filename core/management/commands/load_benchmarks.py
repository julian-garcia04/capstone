import json
import os
from django.core.management.base import BaseCommand
from core.models import DivisionBenchmark
from django.conf import settings

class Command(BaseCommand):
    help = 'Loads scraped benchmark data from a JSON file into the database.'

    def add_arguments(self, parser):
        # Allow the user to specify a file path, defaulting to 'scraped_benchmarks.json' in the project root
        parser.add_argument(
            '--file',
            type=str,
            default=os.path.join(settings.BASE_DIR, 'scraped_benchmarks.json'),
            help='Path to the JSON file containing the benchmarks'
        )

    def handle(self, *args, **kwargs):
        file_path = kwargs['file']

        if not os.path.exists(file_path):
            self.stdout.write(self.style.ERROR(f"File not found: {file_path}"))
            self.stdout.write(self.style.WARNING("Make sure you run 'python scraper.py' first to generate the file."))
            return

        with open(file_path, 'r') as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError:
                self.stdout.write(self.style.ERROR(f"Invalid JSON in file: {file_path}"))
                return

        created_count = 0
        updated_count = 0

        for item in data:
            # We use update_or_create so we don't get duplicates if we run this multiple times
            obj, created = DivisionBenchmark.objects.update_or_create(
                division=item['division'],
                test_name=item['test_name'],
                defaults={
                    'category': item['category'],
                    'raw_value': item['raw_value'],
                    'threshold_min': item['threshold_min'],
                    'threshold_max': item['threshold_max'],
                }
            )
            
            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(self.style.SUCCESS(
            f"Successfully loaded benchmarks! Created: {created_count}, Updated: {updated_count}"
        ))
