from pydantic import BaseModel, Field
from datetime import date
from typing import Optional

class AthleteCreate(BaseModel):
    name: str
    grad_year: int = Field(ge=2024, le=2032)
    position: str

    gpa: Optional[float] = Field(None, ge=0.0, le=4.0)
    height_cm: Optional[float] = Field(None, gt=120, lt=230)
    weight_kg: Optional[float] = Field(None, gt=35, lt=160)

    sprint_30m: Optional[float] = Field(None, gt=3.0, lt=7.0)
    agility_t: Optional[float] = Field(None, gt=7.0, lt=13.0)
    beep_level: Optional[float] = Field(None, ge=1, le=20)

    test_date: Optional[date] = None
