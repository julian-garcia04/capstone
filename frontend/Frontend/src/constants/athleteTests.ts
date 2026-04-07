/** Field names match Django `AthleteTest` model (capstone API). */

export type TestFieldKey =
  | "sprint_40yd"
  | "sprint_30m"
  | "flying_sprint"
  | "accel_10m"
  | "split_5m"
  | "split_10m"
  | "split_20m"
  | "agility_t"
  | "shuttle_run"
  | "lateral_agility"
  | "illinois_agility"
  | "beep_level"
  | "cooper_test"
  | "interval_run"
  | "vertical_jump"
  | "broad_jump"
  | "medicine_ball_throw"
  | "push_ups"
  | "sit_ups"
  | "plank"
  | "lunges"
  | "box_jump";

export const TEST_FIELD_LABELS: Record<TestFieldKey, string> = {
  sprint_40yd: "40-yard dash",
  sprint_30m: "30 m sprint",
  flying_sprint: "Flying sprint",
  accel_10m: "10 m acceleration",
  split_5m: "5 m split",
  split_10m: "10 m split",
  split_20m: "20 m split",
  agility_t: "T-test",
  shuttle_run: "Shuttle run",
  lateral_agility: "Lateral agility",
  illinois_agility: "Illinois agility",
  beep_level: "Beep test level",
  cooper_test: "Cooper test",
  interval_run: "Interval run",
  vertical_jump: "Vertical jump",
  broad_jump: "Broad jump",
  medicine_ball_throw: "Medicine ball throw",
  push_ups: "Push-ups",
  sit_ups: "Sit-ups",
  plank: "Plank",
  lunges: "Lunges",
  box_jump: "Box jump",
};

/**
 * Display units aligned with division benchmarks (fixtures / evaluator).
 * Use in labels, summaries, and readouts — API still stores plain numbers.
 */
export const TEST_FIELD_UNIT_HINTS: Record<TestFieldKey, string> = {
  sprint_40yd: "seconds",
  sprint_30m: "seconds",
  flying_sprint: "seconds",
  accel_10m: "seconds",
  split_5m: "seconds",
  split_10m: "seconds",
  split_20m: "seconds",
  agility_t: "seconds",
  shuttle_run: "seconds",
  lateral_agility: "seconds",
  illinois_agility: "seconds",
  beep_level: "level (Yo-Yo / beep)",
  cooper_test: "meters (12-min distance)",
  interval_run: "meters (distance covered)",
  vertical_jump: "inches",
  broad_jump: "feet (standing broad jump)",
  medicine_ball_throw: "feet (throw distance)",
  push_ups: "reps (e.g. per minute)",
  sit_ups: "reps (e.g. per minute)",
  plank: "minutes",
  lunges: "reps per leg (e.g. per minute)",
  box_jump: "inches (box height)",
};

/** Short suffix after a numeric value in tables and summaries */
export const TEST_FIELD_UNIT_SUFFIX: Record<TestFieldKey, string> = {
  sprint_40yd: "s",
  sprint_30m: "s",
  flying_sprint: "s",
  accel_10m: "s",
  split_5m: "s",
  split_10m: "s",
  split_20m: "s",
  agility_t: "s",
  shuttle_run: "s",
  lateral_agility: "s",
  illinois_agility: "s",
  beep_level: "lvl",
  cooper_test: "m",
  interval_run: "m",
  vertical_jump: "in",
  broad_jump: "ft",
  medicine_ball_throw: "ft",
  push_ups: "reps",
  sit_ups: "reps",
  plank: "min",
  lunges: "reps",
  box_jump: "in",
};

function trimNumberDisplay(n: number): string {
  if (Number.isInteger(n)) return String(n);
  const s = n.toFixed(2).replace(/\.?0+$/, "");
  return s || "0";
}

/** Label + unit for form fields, e.g. "40-yard dash (seconds)" */
export function testFieldLabelWithUnit(key: TestFieldKey): string {
  return `${TEST_FIELD_LABELS[key]} (${TEST_FIELD_UNIT_HINTS[key]})`;
}

/** Format a stored test value with its unit for history / readouts */
export function formatAthleteTestMetric(key: TestFieldKey, value: string | number | null | undefined): string | null {
  if (value === null || value === undefined || value === "") return null;
  const num = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(num)) return `${value} ${TEST_FIELD_UNIT_SUFFIX[key]}`;
  return `${trimNumberDisplay(num)} ${TEST_FIELD_UNIT_SUFFIX[key]}`;
}

export const TEST_FIELD_GROUPS: { title: string; keys: TestFieldKey[] }[] = [
  {
    title: "Speed & splits",
    keys: [
      "sprint_40yd",
      "sprint_30m",
      "flying_sprint",
      "accel_10m",
      "split_5m",
      "split_10m",
      "split_20m",
    ],
  },
  {
    title: "Agility",
    keys: ["agility_t", "shuttle_run", "lateral_agility", "illinois_agility"],
  },
  {
    title: "Endurance",
    keys: ["beep_level", "cooper_test", "interval_run"],
  },
  {
    title: "Power & jumps",
    keys: ["vertical_jump", "broad_jump", "medicine_ball_throw", "box_jump"],
  },
  {
    title: "Strength & conditioning",
    keys: ["push_ups", "sit_ups", "plank", "lunges"],
  },
];

export const ALL_TEST_KEYS: TestFieldKey[] = TEST_FIELD_GROUPS.flatMap((g) => g.keys);
