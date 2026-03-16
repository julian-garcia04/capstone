from django.db import models
from django.contrib.auth.models import User  # Import Django's built-in User model


# ── 1. User Model ────────────────────────────────────────────────
# We are using Django's built-in User model for authentication.


# ── 2. Athlete Profile ──────────────────────────────────────────
# Extends Django's User model with athlete-specific data.
class Athlete(models.Model):
    # Links to Django's User model.  One user <-> one athlete profile.
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='athlete_profile')
    grad_year = models.IntegerField(null=True, blank=True)
    height_in = models.FloatField(null=True, blank=True)
    weight_lb = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"Athlete: {self.user.username}"


# ── 3. Athlete Test Results ─────────────────────────────────────
# Stores individual test results for an athlete.
# Allows tracking progress over time.
class AthleteTest(models.Model):
    # Links to the Athlete model. One athlete <-> many test results.
    athlete = models.ForeignKey(Athlete, on_delete=models.CASCADE, related_name='tests')
    test_date = models.DateField(auto_now_add=True)  # Automatically set on creation

    # Test fields (all optional)
    sprint_40yd = models.FloatField(null=True, blank=True)
    sprint_30m = models.FloatField(null=True, blank=True)
    flying_sprint = models.FloatField(null=True, blank=True)
    accel_10m = models.FloatField(null=True, blank=True)
    split_5m = models.FloatField(null=True, blank=True)
    split_10m = models.FloatField(null=True, blank=True)
    split_20m = models.FloatField(null=True, blank=True)
    agility_t = models.FloatField(null=True, blank=True)
    shuttle_run = models.FloatField(null=True, blank=True)
    lateral_agility = models.FloatField(null=True, blank=True)
    illinois_agility = models.FloatField(null=True, blank=True)
    beep_level = models.FloatField(null=True, blank=True)
    cooper_test = models.FloatField(null=True, blank=True)
    interval_run = models.FloatField(null=True, blank=True)
    vertical_jump = models.FloatField(null=True, blank=True)
    broad_jump = models.FloatField(null=True, blank=True)
    medicine_ball_throw = models.FloatField(null=True, blank=True)
    push_ups = models.FloatField(null=True, blank=True)
    sit_ups = models.FloatField(null=True, blank=True)
    plank = models.FloatField(null=True, blank=True)
    lunges = models.FloatField(null=True, blank=True)
    box_jump = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ['-test_date']  # Most recent test first


# ── 4. Division Benchmarks ──────────────────────────────────────
# Stores benchmark data for different divisions and tests.
class DivisionBenchmark(models.Model):
    division = models.CharField(max_length=50)
    category = models.CharField(max_length=100)
    test_name = models.CharField(max_length=100)
    raw_value = models.CharField(max_length=100)
    threshold_min = models.FloatField(null=True, blank=True)
    threshold_max = models.FloatField(null=True, blank=True)

    class Meta:
        unique_together = ('division', 'test_name')  # Ensure unique benchmarks

    def __str__(self):
        return f"{self.division} - {self.test_name}"