"""
FIT EVALUATION ENGINE - CORE LOGIC
PURPOSE:
This module handles the comparison between raw athlete test results and
divisional benchmarks.

LOGIC PRINCIPLES:
1. POINT SYSTEM: 
   - 1.0 (MEETS): Athlete is at or better than the benchmark.
   - 0.5 (NEAR): Athlete is within a 2% tolerance of the benchmark.
   - 0.0 (BELOW): Athlete is significantly outside the required range.

2. 2% TOLERANCE BAND:
   Athletic testing has a natural margin of error. 
   A 2% buffer identifies athletes who are "close enough" 
   to a benchmark to be considered recruitable with further development.

3. ALIGNMENT & RECOMMENDATION:
   The 'Overall Alignment' is the average of points earned. A recommendation 
   is made for the highest division where the athlete scores >= 80% alignment.
"""

class FitEvaluationEngine:
    def __init__(self):
        # Maps database field names from models.py to benchmark test_names
        self.test_mapping = {
            "40-Yard Dash": "sprint_40yd",
            "30-Meter Sprint": "sprint_30m",
            "Flying Sprints": "flying_sprint",
            "10-meter acceleration test": "accel_10m",
            "5/10/20-Meter Sprint": "split_5m",
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
        
        # Sprints and Agility tests where a LOWER time is better
        self.lower_is_better = [
            "40-Yard Dash", "30-Meter Sprint", "Flying Sprints", 
            "10-meter acceleration test", "5/10/20-Meter Sprint", 
            "T-Test", "Shuttle Run", "Lateral Agility Test", "Illinois Agility Test"
        ]
        
        self.tolerance = 0.02 

    def get_status_and_score(self, test_name, player_value, benchmark):
        if player_value is None:
            return "MISSING", 0.0

        # Logic for Sprints/Agility (Lower is Better)
        if test_name in self.lower_is_better:
            target = benchmark.threshold_max # Max allowed time
            if target is None: return "MISSING", 0.0

            if player_value <= target:
                return "MEETS", 1.0
            elif player_value <= (target * (1 + self.tolerance)):
                return "NEAR", 0.5
            return "BELOW", 0.0

        # Logic for Power/Endurance (Higher is Better)
        else:
            target = benchmark.threshold_min # Min required level/distance
            if target is None: return "MISSING", 0.0

            if player_value >= target:
                return "MEETS", 1.0
            elif player_value >= (target * (1 - self.tolerance)):
                return "NEAR", 0.5
            return "BELOW", 0.0

    def run_evaluation(self, athlete_test, all_benchmarks):
        divisions = ["Division 1", "Division 2", "Division 3", "NAIA", "JUCO"]
        report = {"division_alignment": {}, "recommended_division": "Developing", "strengths": [], "weaknesses": []}
        alignment_scores = {}

        for div_name in divisions:
            div_benchmarks = [b for b in all_benchmarks if b.division == div_name]
            total_points = 0.0
            valid_metrics = 0

            for bm in div_benchmarks:
                field_name = self.test_mapping.get(bm.test_name)
                if field_name:
                    val = getattr(athlete_test, field_name, None) #
                    status, points = self.get_status_and_score(bm.test_name, val, bm)

                    if status != "MISSING":
                        total_points += points
                        valid_metrics += 1

            score = (total_points / valid_metrics * 100) if valid_metrics > 0 else 0
            alignment_scores[div_name] = score
            report["division_alignment"][div_name] = round(score, 1)

        # Recommendation based on 80% Threshold
        for div in divisions:
            if alignment_scores.get(div, 0) >= 80.0:
                report["recommended_division"] = div
                break

        # Strength/Weakness Generation based on Recommendation
        rec_div = report["recommended_division"]
        if rec_div != "Developing":
            rec_benchmarks = [b for b in all_benchmarks if b.division == rec_div]
            for bm in rec_benchmarks:
                field_name = self.test_mapping.get(bm.test_name)
                val = getattr(athlete_test, field_name, None)
                status, _ = self.get_status_and_score(bm.test_name, val, bm)
                
                if status == "MEETS":
                    report["strengths"].append(f"{bm.test_name} is a {rec_div} strength.")
                elif status == "BELOW":
                    report["weaknesses"].append(f"{bm.test_name} is below {rec_div} standards.")

        return report
