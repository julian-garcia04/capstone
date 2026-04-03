from rest_framework import serializers
from django.contrib.auth.models import User # Import Django's built in User
from .models import Athlete, AthleteTest, DivisionBenchmark

# ── 1. User Registration ──────────────────────────────────────

class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        # The default User model requires a username and password.
        # We don't need confirm_password
        fields = ['username', 'password']

    def create(self, validated_data):
        # Use the built-in create_user method which handles password hashing
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password']
        )
        return user


# ── 2. Athlete & Tests ────────────────────────────────────────

class AthleteTestSerializer(serializers.ModelSerializer):
    class Meta:
        model = AthleteTest
        exclude = ['athlete'] 

class AthleteSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    tests = AthleteTestSerializer(many=True, read_only=True)

    class Meta:
        model = Athlete
        fields = ['id', 'username', 'grad_year', 'height_in', 'weight_lb', 'tests']


# ── 3. Benchmarks ─────────────────────────────────────────────

class BenchmarkSerializer(serializers.ModelSerializer):
    class Meta:
        model = DivisionBenchmark
        fields = '__all__'
