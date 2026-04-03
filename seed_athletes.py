import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'capstone_v2.settings')
django.setup()

from django.contrib.auth.models import User
from core.models import Athlete, AthleteTest

# ─────────────────────────────────────────────────────────────────────────────
#  seed_athletes.py
#  Run: python seed_athletes.py
#
#  Creates the following test accounts (password: testpass123 for all):
#
#  Original division benchmarks
#    d1_player      — scores at D1 level across all tests
#    d2_player      — scores at D2 level across all tests
#    d3_player      — scores at D3 level across all tests
#    hybrid_player  — mixed: D1 speed, D3 power, D1/D2 agility, D3 endurance
#
#  Colour-tier testing (vs D1 standard)
#    pct_60_player  — all scores at exactly 60% of D1 standard (yellow/red boundary)
#    pct_80_player  — all scores at exactly 80% of D1 standard (yellow zone)
#    pct_90_player  — all scores at exactly 90% of D1 standard (yellow/green boundary)
#
#  Null / partial entry testing
#    null_all       — no test scores at all (all fields null)
#    null_partial   — some scores recorded, some null
#    zero_scores    — explicit zeros on higher-is-better tests (vertical, beep)
#
#  Variety athletes (realistic mixed profiles)
#    speed_only     — fast 40yd but poor on everything else
#    power_only     — huge vertical but slow and poor agility/endurance
#    almost_d1      — one test just barely missing D1 on each metric
#    overachiever   — exceeds D1 standard on all tests (tests >100% display)
# ─────────────────────────────────────────────────────────────────────────────

def create_sample_players():
    print("Starting to seed athlete data...")

    players_data = [

        # ── Original athletes ─────────────────────────────────────────────────

        {
            "username": "d1_player",
            "profile": {"grad_year": 2025, "height_in": 74, "weight_lb": 195},
            "test_scores": {
                "sprint_40yd": 4.50,    # D1 speed    (114% of 5.0 cutoff)
                "vertical_jump": 34.0,  # D1 power    (189% of 18.0 cutoff)
                "agility_t": 8.5,       # D1 agility  (106% of 9.0 cutoff)
                "beep_level": 21.0      # D1 endurance(162% of 13.0 cutoff)
            }
        },
        {
            "username": "d2_player",
            "profile": {"grad_year": 2026, "height_in": 71, "weight_lb": 175},
            "test_scores": {
                "sprint_40yd": 4.75,    # D2 speed
                "vertical_jump": 29.0,  # D2 power
                "agility_t": 9.2,       # D2 agility
                "beep_level": 18.0      # D2 endurance
            }
        },
        {
            "username": "d3_player",
            "profile": {"grad_year": 2026, "height_in": 69, "weight_lb": 160},
            "test_scores": {
                "sprint_40yd": 5.00,    # D3 speed
                "vertical_jump": 24.0,  # D3 power
                "agility_t": 10.0,      # D3 agility
                "beep_level": 15.0      # D3 endurance
            }
        },
        {
            "username": "hybrid_player",
            "profile": {"grad_year": 2027, "height_in": 73, "weight_lb": 185},
            "test_scores": {
                "sprint_40yd": 4.55,    # D1 level speed
                "vertical_jump": 25.0,  # D3 level power
                "agility_t": 8.7,       # D1/D2 level agility
                "beep_level": 16.0      # D3 level endurance
            }
        },

        # ── Colour-tier benchmark athletes ────────────────────────────────────
        # Scores calculated as exact % of D1 standard:
        #   40yd  cutoff = 5.0  (lower better)  => score = 5.0  / (pct/100)
        #   vert  cutoff = 18.0 (higher better) => score = 18.0 * (pct/100)
        #   ttest cutoff = 9.0  (lower better)  => score = 9.0  / (pct/100)
        #   beep  cutoff = 13.0 (higher better) => score = 13.0 * (pct/100)

        {
            "username": "pct_60_player",
            "profile": {"grad_year": 2027, "height_in": 68, "weight_lb": 155},
            "test_scores": {
                "sprint_40yd": 8.33,    # 60% of D1 — red zone
                "vertical_jump": 10.8,  # 60% of D1 — red zone
                "agility_t": 15.0,      # 60% of D1 — red zone
                "beep_level": 7.8       # 60% of D1 — red zone
            }
        },
        {
            "username": "pct_80_player",
            "profile": {"grad_year": 2026, "height_in": 70, "weight_lb": 168},
            "test_scores": {
                "sprint_40yd": 6.25,    # 80% of D1 — yellow zone
                "vertical_jump": 14.4,  # 80% of D1 — yellow zone
                "agility_t": 11.25,     # 80% of D1 — yellow zone
                "beep_level": 10.4      # 80% of D1 — yellow zone
            }
        },
        {
            "username": "pct_90_player",
            "profile": {"grad_year": 2025, "height_in": 72, "weight_lb": 180},
            "test_scores": {
                "sprint_40yd": 5.56,    # 90% of D1 — yellow zone (just under)
                "vertical_jump": 16.2,  # 90% of D1 — yellow zone
                "agility_t": 10.0,      # 90% of D1 — yellow zone
                "beep_level": 11.7      # 90% of D1 — yellow zone
            }
        },

        # ── Null / partial entry testing ──────────────────────────────────────

        {
            "username": "null_all",
            "profile": {"grad_year": 2028, "height_in": 71, "weight_lb": 170},
            "test_scores": {
                "sprint_40yd": None,    # no scores recorded at all
                "vertical_jump": None,
                "agility_t": None,
                "beep_level": None
            }
        },
        {
            "username": "null_partial",
            "profile": {"grad_year": 2027, "height_in": 73, "weight_lb": 178},
            "test_scores": {
                "sprint_40yd": 4.90,    # recorded
                "vertical_jump": None,  # not yet tested
                "agility_t": 9.5,       # recorded
                "beep_level": None      # not yet tested
            }
        },
        {
            "username": "zero_scores",
            "profile": {"grad_year": 2027, "height_in": 69, "weight_lb": 162},
            "test_scores": {
                "sprint_40yd": 4.80,    # normal score
                "vertical_jump": 0,     # explicit zero — should show 0, not break
                "agility_t": 9.8,       # normal score
                "beep_level": 0         # explicit zero — should show 0, not break
            }
        },

        # ── Variety / realistic mixed profiles ────────────────────────────────

        {
            "username": "speed_only",
            "profile": {"grad_year": 2026, "height_in": 70, "weight_lb": 158},
            "test_scores": {
                "sprint_40yd": 4.40,    # elite speed (>100% D1)
                "vertical_jump": 12.0,  # poor power (~67% D1 — red)
                "agility_t": 11.5,      # poor agility (~78% D1 — yellow)
                "beep_level": 8.0       # poor endurance (~62% D1 — yellow)
            }
        },
        {
            "username": "power_only",
            "profile": {"grad_year": 2025, "height_in": 76, "weight_lb": 215},
            "test_scores": {
                "sprint_40yd": 6.10,    # slow (82% D1 — yellow)
                "vertical_jump": 38.0,  # elite power (>100% D1)
                "agility_t": 11.0,      # poor agility (~82% D1 — yellow)
                "beep_level": 9.0       # below average (~69% D1 — red)
            }
        },
        {
            "username": "almost_d1",
            "profile": {"grad_year": 2025, "height_in": 73, "weight_lb": 188},
            "test_scores": {
                "sprint_40yd": 5.10,    # just misses D1 (98% — yellow)
                "vertical_jump": 17.5,  # just misses D1 (97% — yellow)
                "agility_t": 9.15,      # just misses D1 (98% — yellow)
                "beep_level": 12.5      # just misses D1 (96% — yellow)
            }
        },
        {
            "username": "overachiever",
            "profile": {"grad_year": 2025, "height_in": 75, "weight_lb": 192},
            "test_scores": {
                "sprint_40yd": 4.20,    # well above D1 (~119% — green)
                "vertical_jump": 40.0,  # well above D1 (~222% — green)
                "agility_t": 7.8,       # well above D1 (~115% — green)
                "beep_level": 25.0      # well above D1 (~192% — green)
            }
        },
    ]

    for data in players_data:
        username = data["username"]

        user, created = User.objects.get_or_create(username=username)
        if created:
            user.set_password("testpass123")
            user.save()
            print(f"  Created user:  {username}")
        else:
            print(f"  Exists:        {username} — updating profile...")

        athlete, _ = Athlete.objects.get_or_create(user=user)
        athlete.grad_year = data["profile"]["grad_year"]
        athlete.height_in = data["profile"]["height_in"]
        athlete.weight_lb = data["profile"]["weight_lb"]
        athlete.save()

        # Build kwargs, skipping None values so nullable fields stay null
        scores = {k: v for k, v in data["test_scores"].items() if v is not None}
        test_entry = AthleteTest(athlete=athlete, **scores)
        test_entry.save()
        print(f"    -> Test scores saved for {username}")

    print("\n✅ Seeding complete!")
    print("=" * 50)
    print("All passwords: testpass123")
    print()
    print("Accounts created:")
    print("  d1_player       — full D1 scores")
    print("  d2_player       — full D2 scores")
    print("  d3_player       — full D3 scores")
    print("  hybrid_player   — mixed D1/D3 scores")
    print("  pct_60_player   — all at 60% of D1 (red zone)")
    print("  pct_80_player   — all at 80% of D1 (yellow zone)")
    print("  pct_90_player   — all at 90% of D1 (yellow zone)")
    print("  null_all        — no test scores at all")
    print("  null_partial    — two scores null, two recorded")
    print("  zero_scores     — vertical and beep explicitly = 0")
    print("  speed_only      — elite speed, poor everything else")
    print("  power_only      — elite vertical, slow/poor elsewhere")
    print("  almost_d1       — every metric just below D1 (~97-98%)")
    print("  overachiever    — exceeds D1 on all four tests")

if __name__ == "__main__":
    create_sample_players()