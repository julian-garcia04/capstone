"""
FIT EVALUATION ENGINE - CORE LOGIC (v2.1)

Puropse:
To provide high school athletes with a realistic "Scouting Report" by comparing
their raw test scores against NCAA Division 1, 2, and 3 benchmarks.

Details:
1. SCORING:
   - Full Credit (1.0): Met or beat the college standard.
   - Partial Credit (0.5): Within 2% of the goal (The "Developmental Zone").
   - No Credit (0.0): Significantly outside the recruitable range.

2. THE 70% RULE:
   If an athlete's average score across all tests is 70% or higher for a specific
   division, we officially "Recommend" that division to them. I lowered this
   from 80% to account for high schoolers' ability to improve quickly with training.

3. GUARANTEED FEEDBACK:
   No athlete gets an empty report. Even if they don't hit the 70% mark for any
   division, the engine automatically compares them to Division 3 standards to
   generate a list of "Strengths" and "Weaknesses" they can use to start training.

Potential STRETCH GOALS:
- DRILL MAPPING: Automatically suggest specific field drills based on 'Weaknesses.'
- VIDEO COACHING: Provide YouTube tutorial links for any failed test metrics.
- RECRUIT READINESS: Add "Positional Weighting" (e.g., Goalie vs. Striker standards).
"""


class FitEvaluationEngine:
    def __init__(self):
        # Updated to include individual sprint splits
        self.test_mapping = {
            "40-Yard Dash": "sprint_40yd",
            "30-Meter Sprint": "sprint_30m",
            "Flying Sprints": "flying_sprint",
            "10-meter acceleration test": "accel_10m",
            "5/10/20-Meter Sprint": "split_5m",  # Primary mapping
            "10m Sprint": "split_10m",  # Extra field
            "20m Sprint": "split_20m",  # Extra field
            "T-Test": "agility_t",
            "Shuttle Run": "shuttle_run",
            "Lateral Agility Test": "lateral_agility",
            "Illinois Agility Test": "illinois_agility",
            "Yo-Yo Intermittent Recovery Test (Beep Test)": "beep_level",
            "Cooper Test": "cooper_test",
            "Interval Runs": "interval_run",
            "Vertical Jump": "vertical_jump",
            "Standing Broad Jump": "broad_jump",
            "Medicine Ball Throws": "medicine_ball_throw",
            "Push-ups": "push_ups",
            "Sit-ups": "sit_ups",
            "Planks": "plank",
            "Lunges": "lunges",
            "Box Jumps": "box_jump"
        }

        self.lower_is_better = [
            "40-Yard Dash", "30-Meter Sprint", "Flying Sprints",
            "10-meter acceleration test", "5/10/20-Meter Sprint",
            "10m Sprint", "20m Sprint", "T-Test", "Shuttle Run",
            "Lateral Agility Test", "Illinois Agility Test"
        ]

        self.tolerance = 0.02
        self.rec_threshold = 70.0  # Lowered from 80% to be more inclusive

    def get_status_and_score(self, test_name, player_value, benchmark):
        if player_value is None:
            return "MISSING", 0.0

        if test_name in self.lower_is_better:
            target = benchmark.threshold_max
            if target is None: return "MISSING", 0.0
            if player_value <= target:
                return "MEETS", 1.0
            elif player_value <= (target * (1 + self.tolerance)):
                return "NEAR", 0.5
            return "BELOW", 0.0
        else:
            target = benchmark.threshold_min
            if target is None: return "MISSING", 0.0
            if player_value >= target:
                return "MEETS", 1.0
            elif player_value >= (target * (1 - self.tolerance)):
                return "NEAR", 0.5
            return "BELOW", 0.0

    def run_evaluation(self, athlete_test, all_benchmarks):
        # Now strictly NCAA Divisions 1-3
        divisions = ["Division 1", "Division 2", "Division 3"]
        report = {"division_alignment": {}, "recommended_division": "Developing", "strengths": [], "weaknesses": []}
        alignment_scores = {}

        for div_name in divisions:
            div_benchmarks = [b for b in all_benchmarks if b.division == div_name]
            total_points = 0.0
            valid_metrics = 0

            for bm in div_benchmarks:
                field_name = self.test_mapping.get(bm.test_name)
                if field_name:
                    val = getattr(athlete_test, field_name, None)
                    status, points = self.get_status_and_score(bm.test_name, val, bm)
                    if status != "MISSING":
                        total_points += points
                        valid_metrics += 1

            score = (total_points / valid_metrics * 100) if valid_metrics > 0 else 0
            alignment_scores[div_name] = score
            report["division_alignment"][div_name] = round(score, 1)

        # Recommendation Logic (70% Threshold)
        for div in divisions:
            if alignment_scores.get(div, 0) >= self.rec_threshold:
                report["recommended_division"] = div
                break

        # FEEDBACK LOGIC:
        # If they meet a division, compare against that.
        # IF they are "Developing," compare against Division 3 to give them a goal.
        target_feedback_div = report["recommended_division"]
        if target_feedback_div == "Developing":
            target_feedback_div = "Division 3"

        feedback_benchmarks = [b for b in all_benchmarks if b.division == target_feedback_div]
        for bm in feedback_benchmarks:
            field_name = self.test_mapping.get(bm.test_name)
            val = getattr(athlete_test, field_name, None)
            status, _ = self.get_status_and_score(bm.test_name, val, bm)

            if status == "MEETS":
                report["strengths"].append(f"{bm.test_name} is a {target_feedback_div} strength.")
            elif status == "BELOW":
                report["weaknesses"].append(f"{bm.test_name} is currently below {target_feedback_div} standards.")

        return report