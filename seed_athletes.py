import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'capstone_v2.settings')
django.setup()

from django.contrib.auth.models import User
from core.models import Athlete, AthleteTest

# Run python seed_athletes.py     ------ Adds sample player data for D1, D2, D3, and Hybrid athletes.
#                                 ------ Will add this to a data migration later.

def create_sample_players():
    print("Starting to seed athlete data...")

    players_data = [
        {
            "username": "d1_player",
            "profile": {"grad_year": 2025, "height_in": 74, "weight_lb": 195},
            "test_scores": {
                "sprint_40yd": 4.50,        # D1 speed
                "vertical_jump": 34.0,      # D1 power
                "agility_t": 8.5,           # D1 agility
                "beep_level": 21.0          # D1 endurance
            }
        },
        {
            "username": "d2_player",
            "profile": {"grad_year": 2026, "height_in": 71, "weight_lb": 175},
            "test_scores": {
                "sprint_40yd": 4.75,        # D2 speed
                "vertical_jump": 29.0,      # D2 power
                "agility_t": 9.2,           # D2 agility
                "beep_level": 18.0          # D2 endurance
            }
        },
        {
            "username": "d3_player",
            "profile": {"grad_year": 2026, "height_in": 69, "weight_lb": 160},
            "test_scores": {
                "sprint_40yd": 5.00,        # D3 speed
                "vertical_jump": 24.0,      # D3 power
                "agility_t": 10.0,          # D3 agility
                "beep_level": 15.0          # D3 endurance
            }
        },
        {
            "username": "hybrid_player",
            "profile": {"grad_year": 2027, "height_in": 73, "weight_lb": 185},
            "test_scores": {
                "sprint_40yd": 4.55,        # D1 level speed
                "vertical_jump": 25.0,      # D3 level power
                "agility_t": 8.7,           # D1/D2 level agility
                "beep_level": 16.0          # D3 level endurance
            }
        }
    ]

    for data in players_data:
        username = data["username"]
        
        # 1. Create the User (if they don't already exist)
        user, created = User.objects.get_or_create(username=username)
        if created:
            user.set_password("testpass123") # password for testing
            user.save()
            print(f"Created user: {username}")
        else:
            print(f"User {username} already exists, updating their data...")

        # 2. Update the Athlete Profile
        athlete, _ = Athlete.objects.get_or_create(user=user)
        athlete.grad_year = data["profile"]["grad_year"]
        athlete.height_in = data["profile"]["height_in"]
        athlete.weight_lb = data["profile"]["weight_lb"]
        athlete.save()

        # 3. Create a new Test Result entry for them
        test_entry = AthleteTest(athlete=athlete, **data["test_scores"])
        test_entry.save()
        print(f"  -> Added test results for {username}")

    print("\n✅ Seeding complete! You can now log in with these accounts.")
    print("Passwords for all accounts: testpass123")

if __name__ == "__main__":
    create_sample_players()
