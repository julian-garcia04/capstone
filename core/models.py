from django.db import models
from django.contrib.auth.models import User  # Import Django's built-in User model


# ── We no longer need a custom User or UserManager ────────────────


# ── 2. Athlete Setup ──────────────────────────────────────────
# Links to Django's built-in User model now.
class Athlete(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='athlete_profile')
    grad_year = models.IntegerField(null=True, blank=True)
    height_in = models.FloatField(null=True, blank=True)
    weight_lb = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"Athlete: {self.user.username}"


# ── 3. Test Results Setup ─────────────────────────────────────
# We keep this separate from Athlete so a user can track their progress over time
class AthleteTest(models.Model):
    athlete = models.ForeignKey(Athlete, on_delete=models.CASCADE, related_name='tests')
    test_date = models.DateField(auto_now_add=True)

    # ... (all your test fields remain the same)
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
        ordering = ['-test_date']


# ── 4. Benchmarks Setup ───────────────────────────────────────
class DivisionBenchmark(models.Model):
    division = models.CharField(max_length=50)
    category = models.CharField(max_length=100)
    test_name = models.CharField(max_length=100)
    raw_value = models.CharField(max_length=100)
    threshold_min = models.FloatField(null=True, blank=True)
    threshold_max = models.FloatField(null=True, blank=True)

    class Meta:
        unique_together = ('division', 'test_name')

    def __str__(self):
        return f"{self.division} - {self.test_name}"