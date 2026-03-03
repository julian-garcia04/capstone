from sqlalchemy import Column, Integer, String, Float, Date, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from db import Base


class User(Base):
    # Stores login account info for every registered user.
    # Fields:
    #     id, first_name, last_name, username, email, school, grad_year, password, created_at
    # Relationships:
    #     athlete_profile: the single athlete profile linked to this user account (one-to-one)
    __tablename__ = "users"

    id         = Column(Integer, primary_key=True, index=True)            # auto-generated unique ID
    first_name = Column(String, nullable=False)                            # user's first name
    last_name  = Column(String, nullable=False)                            # user's last name
    username   = Column(String, unique=True, nullable=False, index=True)  # login name
    email      = Column(String, unique=True, nullable=False)               # email address
    school     = Column(String, nullable=False)                            # high school name
    grad_year  = Column(Integer, nullable=False)                           # expected graduation year
    password   = Column(String, nullable=False)                            # hashed password (never plain text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())  # account creation timestamp

    athlete_profile = relationship("Athlete", back_populates="owner", uselist=False)

    # ------------------------------------------------------------------
    # COACH FEATURES (not yet supported — uncomment when coach view is built)
    # ------------------------------------------------------------------
    # role = Column(String, nullable=False, default="player")
    #   ^ what type of account this is: "player" or "coach"
    #
    # submitted_athletes = relationship("Athlete", back_populates="submitted_by_user",
    #                                   foreign_keys="Athlete.submitted_by")
    #   ^ list of athlete profiles a coach has submitted
    # ------------------------------------------------------------------


class Athlete(Base):
    # Stores a player's personal info and physical measurements.
    # Fields:
    #     id, name, grad_year, position, height_in, weight_lb, owner_id
    # Relationships:
    #     owner: the User account that owns this profile
    #     tests: all test result rows for this athlete (deletes with athlete)
    __tablename__ = "athletes"

    id        = Column(Integer, primary_key=True, index=True)  # auto-generated unique ID
    name      = Column(String, nullable=False)                  # athlete's full name
    grad_year = Column(Integer, nullable=False)                 # graduation year
    position  = Column(String, nullable=False)                  # position played (GK, CB, ST, etc.)
    height_in = Column(Float, nullable=True)                    # height in inches
    weight_lb = Column(Float, nullable=True)                    # weight in pounds

    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True, unique=True)  # linked user account
    owner    = relationship("User", back_populates="athlete_profile")

    tests = relationship(
        "AthleteTest",
        back_populates="athlete",
        cascade="all, delete-orphan",  # deleting an athlete also deletes their tests
        order_by="AthleteTest.test_date"
    )

    # ------------------------------------------------------------------
    # COACH FEATURES (not yet supported — uncomment when coach view is built)
    # ------------------------------------------------------------------
    # submitted_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    #   ^ stores the user.id of the coach who entered this athlete's profile
    #
    # submitted_by_user = relationship("User", back_populates="submitted_athletes",
    #                                  foreign_keys=[submitted_by])
    #   ^ lets you do athlete.submitted_by_user to get the coach object
    # ------------------------------------------------------------------


class AthleteTest(Base):
    # Stores one set of performance test results for an athlete — one athlete can have many rows.
    # Fields:
    #     id, athlete_id, test_date, sprint_30m, agility_t, beep_level
    # Relationships:
    #     athlete: links back to the Athlete this test belongs to
    # NOTE: metric column names must match DivisionBenchmark exactly — the fit engine compares them by name
    __tablename__ = "athlete_tests"

    id         = Column(Integer, primary_key=True, index=True)               # auto-generated unique ID
    athlete_id = Column(Integer, ForeignKey("athletes.id"), nullable=False)  # which athlete this belongs to
    test_date  = Column(Date, nullable=True)                                  # date the test was performed

    sprint_30m = Column(Float, nullable=True)  # 30-meter sprint time in seconds  (lower = faster)
    agility_t  = Column(Float, nullable=True)  # T-test agility time in seconds   (lower = better)
    beep_level = Column(Float, nullable=True)  # beep test level reached           (higher = better)

    athlete = relationship("Athlete", back_populates="tests")


class DivisionBenchmark(Base):
    # Stores Kevin's scraped benchmark thresholds for each division and position combination.
    # Fields:
    #     id, division, position, sprint_30m, agility_t, beep_level, updated_at
    # Relationships:
    #     none — this table is read-only reference data used by the fit engine
    __tablename__ = "division_benchmarks"

    id       = Column(Integer, primary_key=True, index=True)
    division = Column(String, nullable=False)  # "D1", "D2", "D3", "NAIA", or "JUCO"
    position = Column(String, nullable=True)   # "GK", "CB", "ST" etc — NULL means applies to all positions

    sprint_30m = Column(Float, nullable=True)  # max allowed time to meet this division (lower = faster)
    agility_t  = Column(Float, nullable=True)  # max allowed time to meet this division
    beep_level = Column(Float, nullable=True)  # minimum level required to meet this division

    updated_at = Column(DateTime(timezone=True), server_default=func.now())  # when this data was last updated

    __table_args__ = (
        UniqueConstraint("division", "position", name="uq_division_position"),  # no duplicate division+position rows
    )
