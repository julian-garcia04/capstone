from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey
from sqlalchemy.orm import relationship
from db import Base

class Athlete(Base):
    __tablename__ = "athletes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    grad_year = Column(Integer, nullable=False)
    position = Column(String, nullable=False)

    gpa = Column(Float, nullable=True)
    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)

    tests = relationship("AthleteTest", back_populates="athlete", cascade="all, delete-orphan")

class AthleteTest(Base):
    __tablename__ = "athlete_tests"

    id = Column(Integer, primary_key=True, index=True)
    athlete_id = Column(Integer, ForeignKey("athletes.id"), nullable=False)

    sprint_30m = Column(Float, nullable=True)
    agility_t = Column(Float, nullable=True)
    beep_level = Column(Float, nullable=True)

    test_date = Column(Date, nullable=True)

    athlete = relationship("Athlete", back_populates="tests")
