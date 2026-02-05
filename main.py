from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from datetime import date

from db import engine, SessionLocal
import models
import schemas

app = FastAPI(title="Recruiting App API")

# Create tables
models.Base.metadata.create_all(bind=engine)

# DB session dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def root():
    return {"status": "ok"}

@app.post("/athlete")
def create_athlete(payload: schemas.AthleteCreate, db: Session = Depends(get_db)):
    athlete = models.Athlete(
        name=payload.name,
        grad_year=payload.grad_year,
        position=payload.position,
        gpa=payload.gpa,
        height_cm=payload.height_cm,
        weight_kg=payload.weight_kg
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

    return {"message": "Athlete created", "athlete_id": athlete.id}
