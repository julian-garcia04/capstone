from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date

from db import engine, SessionLocal
import models
import schemas
import auth

app = FastAPI(title="Recruiting App API")

models.Base.metadata.create_all(bind=engine)


def get_db():
    # Opens a database connection for a route to use, then closes it automatically when the route is done.
    # Args: none
    # Returns: a SQLAlchemy database session (automatically closed after the request finishes)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ── Health ────────────────────────────────────────────────────
@app.get("/")
def root():
    # Returns a simple status check to confirm the server is running.
    # Args: none
    # Returns: JSON Status
    return {"status": "ok"}


# ── Auth routes ───────────────────────────────────────────────
@app.post("/register", response_model=schemas.UserResponse)
def register(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    # Creates a new user account after validating all sign-up fields and hashing the password.
    # Args: payload: UserCreate form data (first name, last name, username, email, school, grad year, password) , db
    # Returns: UserResponse with the new user's account info (password is never included)
    if db.query(models.User).filter(models.User.username == payload.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")
    if db.query(models.User).filter(models.User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = models.User(
        first_name=payload.first_name,
        last_name=payload.last_name,
        username=payload.username,
        email=payload.email,
        school=payload.school,
        grad_year=payload.grad_year,
        password=auth.hash_password(payload.password),
        # confirm_password is not stored — it was only used for validation
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@app.post("/login")
def login(payload: schemas.UserLogin, db: Session = Depends(get_db)):
    # Verifies username and password, then returns the user's ID to use for future requests.
    # Args: payload: UserLogin with username and password , db
    # Returns: JSON: { "message": "Login successful", "user_id": <id> }
    user = db.query(models.User).filter(models.User.username == payload.username).first()
    if not user or not auth.verify_password(payload.password, user.password):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    return {"message": "Login successful", "user_id": user.id}


# ── Athlete routes ────────────────────────────────────────────

@app.post("/athlete", response_model=schemas.AthleteResponse)
def create_athlete(payload: schemas.AthleteCreate, db: Session = Depends(get_db)):
    # Saves a new athlete profile and their first set of test results in a single request.
    # Args: payload: UserLogin with username and password , db
    # Returns: AthleteResponse with the saved athlete profile and their test history
    athlete = models.Athlete(
        name=payload.name,
        grad_year=payload.grad_year,
        position=payload.position,
        height_in=payload.height_in,
        weight_lb=payload.weight_lb
    )
    db.add(athlete)
    db.commit()
    db.refresh(athlete)

    test = models.AthleteTest(
        athlete_id=athlete.id,
        sprint_30m=payload.sprint_30m,
        agility_t=payload.agility_t,
        beep_level=payload.beep_level,
        test_date=payload.test_date or date.today()
    )
    db.add(test)
    db.commit()

    return athlete


# ── Player — view own profile ─────────────────────────────────

@app.get("/athlete/me/{user_id}", response_model=schemas.AthleteResponse)
def get_my_profile(user_id: int, db: Session = Depends(get_db)):
    # Returns a player's full athlete profile and all their test history using their user ID from login.
    # Args: user_id, db
    # Returns: AthleteResponse with profile info and a full list of all test results
    athlete = db.query(models.Athlete).filter(models.Athlete.owner_id == user_id).first()
    if not athlete:
        raise HTTPException(status_code=404, detail="No athlete profile linked to this account")
    return athlete


# ── Fit engine — compare player vs division benchmarks ────────

@app.get("/athlete/{athlete_id}/fit", response_model=schemas.FitResult)
def get_fit_result(athlete_id: int, db: Session = Depends(get_db)):
    # Compares a player's most recent test scores against division benchmarks and returns a projected division.
    # Args : athlete_id, db:        
    # Returns: FitResult with per-metric pass/fail for each division and the highest recommended division
    athlete = db.query(models.Athlete).filter(models.Athlete.id == athlete_id).first()
    if not athlete:
        raise HTTPException(status_code=404, detail="Athlete not found")

    latest_test = (
        db.query(models.AthleteTest)
        .filter(models.AthleteTest.athlete_id == athlete_id)
        .order_by(models.AthleteTest.test_date.desc())
        .first()
    )
    if not latest_test:
        raise HTTPException(status_code=404, detail="No test data found for this athlete")

    benchmarks = (
        db.query(models.DivisionBenchmark)
        .filter(
            (models.DivisionBenchmark.position == athlete.position) |
            (models.DivisionBenchmark.position == None)
        )
        .all()
    )

    METRICS = ["sprint_30m", "agility_t", "beep_level"]
    HIGHER_IS_BETTER = {"beep_level"}

    division_results: dict = {}
    recommended_division = None
    division_order = ["D1", "D2", "D3", "NAIA", "JUCO"]

    for bm in benchmarks:
        metric_comparisons = {}
        all_pass = True

        for metric in METRICS:
            player_val = getattr(latest_test, metric)
            bench_val = getattr(bm, metric)

            if player_val is None or bench_val is None:
                meets = None
            elif metric in HIGHER_IS_BETTER:
                meets = player_val >= bench_val
            else:
                meets = player_val <= bench_val

            if meets is False:
                all_pass = False

            metric_comparisons[metric] = schemas.MetricComparison(
                player_value=player_val,
                benchmark_value=bench_val,
                meets_benchmark=meets
            )

        division_results[bm.division] = metric_comparisons

        if all_pass and bm.division in division_order:
            current_idx = division_order.index(bm.division)
            if recommended_division is None:
                recommended_division = bm.division
            elif division_order.index(recommended_division) > current_idx:
                recommended_division = bm.division

    return schemas.FitResult(
        athlete_id=athlete.id,
        athlete_name=athlete.name,
        position=athlete.position,
        test_date=latest_test.test_date,
        recommended_division=recommended_division,
        divisions=division_results
    )


# ── Benchmark routes (for Kevin to load scraped data) ─────────

@app.get("/benchmarks", response_model=list[schemas.BenchmarkResponse])
def list_benchmarks(db: Session = Depends(get_db)):
    # Returns all stored division benchmark values so the frontend can draw comparison charts.
    # Args: db
    # Returns: list of BenchmarkResponse objects, one per division + position combination
    return db.query(models.DivisionBenchmark).all()


@app.post("/benchmarks", response_model=schemas.BenchmarkResponse)
def upsert_benchmark(payload: schemas.BenchmarkResponse, db: Session = Depends(get_db)):
    # Adds a new benchmark row or updates an existing one when Kevin's scraper posts new division data.
    # Args payload, db:      
    # Returns: BenchmarkResponse of the row that was created or updated
    existing = (
        db.query(models.DivisionBenchmark)
        .filter(
            models.DivisionBenchmark.division == payload.division,
            models.DivisionBenchmark.position == payload.position
        )
        .first()
    )
    if existing:
        existing.sprint_30m = payload.sprint_30m
        existing.agility_t  = payload.agility_t
        existing.beep_level = payload.beep_level
    else:
        existing = models.DivisionBenchmark(**payload.model_dump())
        db.add(existing)

    db.commit()
    db.refresh(existing)
    return existing
