import {
  BarChart3,
  Target,
  Shield,
  TrendingUp,
  Activity,
  BookOpen,
  type LucideIcon,
} from "lucide-react";

export const NAV_LINKS = ["Features", "How It Works", "Divisions", "About"];

export const STATS = [
  { value: "3", label: "NCAA Divisions Benchmarked" },
  { value: "15+", label: "Athletic Metrics Analyzed" },
  { value: "12", label: "Field Positions Covered" },
  { value: "—", label: "Benchmark-based guidance" },
];

export const FEATURES: { icon: LucideIcon; title: string; desc: string }[] = [
  {
    icon: BarChart3,
    title: "Division Benchmarking",
    desc: "Compare your metrics directly against verified NCAA D1, D2, and D3 ranges—organized by position and role.",
  },
  {
    icon: Target,
    title: "Position-Specific Analysis",
    desc: "Expectations differ for a striker vs. a center-back. We map your profile to what coaches at each level actually look for.",
  },
  {
    icon: Activity,
    title: "Multi-Category Scoring",
    desc: "Speed, agility, endurance, power, and strength are scored separately so you know exactly where you stand.",
  },
  {
    icon: TrendingUp,
    title: "Visual Performance Radar",
    desc: "Spider/radar charts give you an instant visual of your strengths and gaps relative to division benchmarks.",
  },
  {
    icon: Shield,
    title: "Honest, Objective Feedback",
    desc: "No hype. Results are presented as guidance—clearly labeled as indicators, not guarantees of recruitment.",
  },
  {
    icon: BookOpen,
    title: "Actionable Improvement Plans",
    desc: "Each metric below benchmark comes with targeted training guidance to help you close the gap before your next evaluation.",
  },
];

export const HOW_IT_WORKS = [
  {
    step: "01",
    title: "Build Your Athlete Profile",
    desc: "Enter your position, academic stats (GPA, test scores), and physical attributes. We support both imperial and metric units.",
  },
  {
    step: "02",
    title: "Input Your Performance Data",
    desc: "Add your tested metrics: 40-yard dash, T-test agility, Beep/Yo-Yo endurance, vertical jump, and strength numbers.",
  },
  {
    step: "03",
    title: "Get Your Division Fit Report",
    desc: "Receive a full analysis showing how your data maps to D1/D2/D3 benchmarks by category and position.",
  },
];

export const DIVISIONS = [
  {
    label: "Division I",
    color: "emerald",
    tagline: "Elite Level",
    desc: "The highest tier of collegiate soccer. Benchmarks reflect full-scholarship programs competing at the national level.",
    highlights: ["Fastest sprint splits", "Highest endurance thresholds", "Elite agility scores"],
  },
  {
    label: "Division II",
    color: "gold",
    tagline: "Competitive Level",
    desc: "Strong programs offering partial scholarships. Metrics are demanding but more accessible than D1.",
    highlights: ["Strong technical foundation", "Good endurance baseline", "Competitive athleticism"],
  },
  {
    label: "Division III",
    color: "muted",
    tagline: "Development Level",
    desc: "No athletic scholarships, but highly competitive play. Academics and character weigh heavily.",
    highlights: ["Solid baseline fitness", "Academic profile emphasis", "Well-rounded athlete"],
  },
];

export const TESTIMONIAL = {
  quote:
    "I had no idea where I stood athletically compared to D1 players until I used Starting XI. The radar chart showed me I was above benchmark in speed but had a real gap in endurance. I spent 8 weeks fixing it.",
  name: "Marcus T.",
  info: "Midfielder — committed D2, targeting D1 transfer",
};

export const FOOTER_LINKS = ["Privacy", "Terms", "Contact"];
