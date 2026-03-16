from django.urls import path
from .views import (
    RegisterView, LoginView,
    AthleteProfileView, AddTestResultView,
    FitResultView, BenchmarkView
)

urlpatterns = [
    # Auth
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),

    # Athlete (No ID needed in URL, it uses the logged-in user's session)
    path('athlete/me/', AthleteProfileView.as_view(), name='my-profile'), 
    path('athlete/tests/', AddTestResultView.as_view(), name='add-test'),
    
    # Fit Engine
    path('athlete/fit/', FitResultView.as_view(), name='my-fit'),

    # Benchmarks
    path('benchmarks/', BenchmarkView.as_view(), name='benchmarks'),
]
