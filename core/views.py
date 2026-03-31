from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import authenticate, login
from django.shortcuts import get_object_or_404
from .models import Athlete, DivisionBenchmark
from .serializers import (
    UserCreateSerializer, AthleteSerializer,
    BenchmarkSerializer, AthleteTestSerializer
)
from .evaluator import FitEvaluationEngine
# ── 1. Auth ───────────────────────────────────────────────────

class RegisterView(generics.CreateAPIView):
    serializer_class = UserCreateSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({"message": "User created", "username": user.username}, status=status.HTTP_201_CREATED)

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get("username")
        password = request.data.get("password")
        
        user = authenticate(request, username=username, password=password)
        if user:
            login(request, user)
            return Response({"message": "Login successful", "username": user.username})
        return Response({"detail": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)


# ── 2. Athlete Profile & Tests ────────────────────────────────

class AthleteProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get my profile and all my tests"""
        athlete, created = Athlete.objects.get_or_create(user=request.user)
        serializer = AthleteSerializer(athlete)
        return Response(serializer.data)

    def put(self, request):
        """Update my height, weight, grad_year"""
        athlete, _ = Athlete.objects.get_or_create(user=request.user)
        
        if 'height_in' in request.data: athlete.height_in = request.data['height_in']
        if 'weight_lb' in request.data: athlete.weight_lb = request.data['weight_lb']
        if 'grad_year' in request.data: athlete.grad_year = request.data['grad_year']
        
        athlete.save()
        return Response(AthleteSerializer(athlete).data)

class AddTestResultView(generics.CreateAPIView):
    """Post a new set of test results (40yd dash, vertical, etc.)"""
    serializer_class = AthleteTestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        athlete, _ = Athlete.objects.get_or_create(user=self.request.user)
        serializer.save(athlete=athlete)


# ── 3. Fit Engine ─────────────────────────────────────────────
class FitResultView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # 1. Get the athlete and their MOST RECENT test (Newest first)
        athlete = get_object_or_404(Athlete, user=request.user)

        # Add order_by to ensure the newest entry is at the top of the list
        latest_test = athlete.tests.order_by('-test_date', '-id').first()

        if not latest_test:
            return Response({"detail": "No test data found. Please add a test first."}, status=400)

        # 2. Get the Answer Key (Benchmarks)
        all_benchmarks = DivisionBenchmark.objects.all()

        # 3. CALL ENGINE
        engine = FitEvaluationEngine()
        report = engine.run_evaluation(latest_test, all_benchmarks)

        # 4. Returns division alignment, recs, and strengths/ weaknesses
        return Response({
            "username": request.user.username,
            "test_date": latest_test.test_date,
            **report
        })

# For when we get to stretch development. This is needed to evaluate multiple test result entries from the athlete.
# As of now, the database will only save test results entered in by the user, not the results from the fit engine.
# Thinking we use pass/fail % for each division. e.g. readiness_score_d1 = 62.6%, readiness_score_d2 = 82.4%
# class BenchmarkHistoryView(APIView):

# ── 4. Benchmarks ───────────────────────────────────────────────
class BenchmarkView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        benchmarks = DivisionBenchmark.objects.all()
        serializer = BenchmarkSerializer(benchmarks, many=True)
        return Response(serializer.data)

    def post(self, request):
        data = request.data
        bm, created = DivisionBenchmark.objects.update_or_create(
            division=data.get('division'), test_name=data.get('test_name'),
            defaults={
                'category': data.get('category'), 'raw_value': data.get('raw_value'),
                'threshold_min': data.get('threshold_min'), 'threshold_max': data.get('threshold_max')
            }
        )
        status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(BenchmarkSerializer(bm).data, status=status_code)
