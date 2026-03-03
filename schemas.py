from pydantic import BaseModel, EmailStr, Field, model_validator
from datetime import date, datetime
from typing import Optional
import re


# ── User schemas ──────────────────────────────────────────────
# This is to ensure password safety and prevent hackability 
# Sign-up only — all fields below are required only when creating a new account.
# Login only needs username + password (see UserLogin below).
class UserCreate(BaseModel):
    first_name:       str = Field(min_length=1, max_length=50)
    last_name:        str = Field(min_length=1, max_length=50)
    username:         str = Field(min_length=3, max_length=32)
    email:            EmailStr
    school:           str = Field(min_length=1, max_length=100)
    grad_year:        int = Field(ge=2025, le=2032)   # expected graduation year
    password:         str = Field(min_length=8)
    confirm_password: str = Field(min_length=8)       # must match password — never stored

    @model_validator(mode="after")
    def validate_password(self):
        # Runs automatically after the form is submitted — enforces all password rules before anything is saved.
        # Args:
        #     self: the completed UserCreate form with all fields filled in
        # Returns:
        #     the validated UserCreate object if all rules pass, raises ValueError if any rule fails
        password         = self.password
        confirm_password = self.confirm_password
        first_name       = (self.first_name or "").lower()
        last_name        = (self.last_name  or "").lower()
        username         = (self.username   or "").lower()
        pwd_lower        = password.lower()

        # Rule 1: passwords must match
        if password != confirm_password:
            raise ValueError("Passwords do not match")

        # Rule 2: must contain at least one special character
        if not re.search(r'[!@#$%^&*()_+\-=\[\]{};\':\\|,.<>\/?]', password):
            raise ValueError("Password must contain at least one special character (e.g. !, @, #, $)")

        # Rule 3: password cannot contain first name, last name, or username (case-insensitive)
        if first_name and first_name in pwd_lower:
            raise ValueError("Password cannot contain your first name")
        if last_name and last_name in pwd_lower:
            raise ValueError("Password cannot contain your last name")
        if username and username in pwd_lower:
            raise ValueError("Password cannot contain your username")

        return self

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    username: str
    email: str
    school: str
    grad_year: int
    created_at: datetime

    class Config:
        from_attributes = True


# ── Athlete schemas ───────────────────────────────────────────
class TestResult(BaseModel):
    """One row of performance data for a player."""
    id: int
    test_date: Optional[date]
    sprint_30m: Optional[float]   # seconds 
    agility_t:  Optional[float]   # seconds 
    beep_level: Optional[float]   # level reached 

    class Config:
        from_attributes = True

class AthleteCreate(BaseModel):
    name: str = Field(min_length=1)
    grad_year: int = Field(ge=2024, le=2032)
    position: str = Field(min_length=1)

    # Imperial measurements only
    height_in: float = Field(gt=47, lt=91)   # ~4'0" to 7'7"
    weight_lb: float = Field(gt=77, lt=352)  # reasonable athletic range

    sprint_30m: Optional[float] = Field(None, gt=3.0, lt=7.0)
    agility_t:  Optional[float] = Field(None, gt=7.0, lt=13.0)
    beep_level: Optional[float] = Field(None, ge=1, le=20)

    test_date: Optional[date] = None

class AthleteResponse(BaseModel):
    id: int
    name: str
    grad_year: int
    position: str
    height_in: Optional[float]
    weight_lb: Optional[float]
    owner_id: Optional[int]
    tests: list[TestResult] = []

    class Config:
        from_attributes = True


# ── Division benchmark schemas ────────────────────────────────

class BenchmarkResponse(BaseModel):
    """One division's benchmark thresholds — mirrors DivisionBenchmark model."""
    division: str
    position: Optional[str]
    sprint_30m: Optional[float]
    agility_t:  Optional[float]
    beep_level: Optional[float]

    class Config:
        from_attributes = True


# ── Fit result schema (comparison output) ────────────────────
class MetricComparison(BaseModel):
    """How a player's score on one metric compares to a division benchmark."""
    player_value: Optional[float]
    benchmark_value: Optional[float]
    meets_benchmark: Optional[bool]

class FitResult(BaseModel):
    """
    Full comparison of a player's latest test against all division benchmarks.
    Used to power charts and the division recommendation.
    """
    athlete_id: int
    athlete_name: str
    position: str
    test_date: Optional[date]
    recommended_division: Optional[str]   # highest division where all metrics are met

    # Per-division breakdown — each key is "D1", "D2", "D3" etc.
    divisions: dict[str, dict[str, MetricComparison]]
