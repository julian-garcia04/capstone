import { useState, useEffect, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { ChevronRight, BarChart3, Target, Shield, TrendingUp, Award, ArrowRight, CheckCircle, Activity, Zap, BookOpen } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog";
import { toast } from "sonner";
import { useAuth } from "@/contexts/AuthContext";

const NAV_LINKS = ["Features", "Divisions"];

const STATS = [
  { value: "3", label: "NCAA Divisions Benchmarked" },
  { value: "15+", label: "Athletic Metrics Analyzed" },
  { value: "12", label: "Field Positions Covered" },
  { value: "—", label: "Benchmark-based guidance" },
];

const FEATURES = [
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

const HOW_IT_WORKS = [
  {
    step: "01",
    title: "Build Your Athlete Profile",
    desc: "Enter your position, grad year, academic stats, and basic background so we can align you with realistic college tiers.",
  },
  {
    step: "02",
    title: "Input Your Performance Data",
    desc: "Add standardized measurables from common college tests: 40-yard dash, T-test agility, Beep/Yo-Yo endurance, vertical jump, and strength numbers.",
  },
  {
    step: "03",
    title: "Get Your Division Fit Report",
    desc: "See how your profile maps to D1/D2/D3 guidelines by position, plus a starting list of programs that match your current fit.",
  },
];

const DIVISIONS = [
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

const TESTIMONIAL = {
  quote:
    "I had no idea where I stood athletically compared to D1 players until I used Starting XI. The radar chart showed me I was above benchmark in speed but had a real gap in endurance. I spent 8 weeks fixing it.",
  name: "Marcus T.",
  info: "Midfielder — committed D2, targeting D1 transfer",
};

export default function Index() {
  const { user, login, register, logout, updateProfile, isSubmitting, isBootstrapping } = useAuth();
  const [scrolled, setScrolled] = useState(false);
  const [activeNav, setActiveNav] = useState<string | null>(null);
  const [authOpen, setAuthOpen] = useState(false);
  const [authMode, setAuthMode] = useState<"signin" | "signup">("signup");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [gradYear, setGradYear] = useState("");

  async function handleAuthSubmit(e: FormEvent) {
    e.preventDefault();
    const u = username.trim();
    const p = password;
    if (!u || !p) {
      toast.error("Enter a username and password.");
      return;
    }
    try {
      if (authMode === "signup") {
        await register(u, p);
        await login(u, p);
        const gy = gradYear.trim();
        if (gy) {
          const y = parseInt(gy, 10);
          if (!Number.isNaN(y)) await updateProfile({ grad_year: y });
        }
        toast.success("Account created. You're signed in.");
      } else {
        await login(u, p);
        toast.success("Signed in.");
      }
      setAuthOpen(false);
      setPassword("");
      setGradYear("");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Request failed.");
    }
  }

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <div className="min-h-screen bg-background font-sans antialiased">
      <header
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          scrolled ? "bg-navy/95 backdrop-blur-md shadow-lg" : "bg-transparent"
        }`}
      >
        <div className="container mx-auto h-16 px-6 flex items-center justify-between md:grid md:grid-cols-[auto,1fr,auto]">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-md bg-emerald">
              <span className="text-sm font-bold text-primary-foreground">XI</span>
            </div>
            <span className="text-lg font-bold tracking-tight text-primary-foreground whitespace-nowrap leading-none">
              Starting XI
            </span>
          </div>

          <nav className="hidden md:flex items-center justify-center gap-8 md:justify-self-center">
            {NAV_LINKS.map((link) => (
              <a
                key={link}
                href={`#${link.toLowerCase().replace(" ", "-")}`}
                className="text-sm font-medium text-primary-foreground/70 transition-colors hover:text-primary-foreground whitespace-nowrap leading-none"
              >
                {link}
              </a>
            ))}
            <Link
              to="/star-player"
              className="text-sm font-medium text-primary-foreground/70 transition-colors hover:text-primary-foreground whitespace-nowrap leading-none"
            >
              Star Player
            </Link>
            <Link
              to="/recruitments"
              className="text-sm font-medium text-primary-foreground/70 transition-colors hover:text-primary-foreground whitespace-nowrap leading-none"
            >
              Recruitments
            </Link>
            <Link
              to="/profile"
              className="text-sm font-medium text-primary-foreground/70 transition-colors hover:text-primary-foreground whitespace-nowrap leading-none"
            >
              My profile
            </Link>
          </nav>

          <Dialog open={authOpen} onOpenChange={setAuthOpen}>
            <div className="flex items-center gap-3 justify-end">
              {!isBootstrapping && user ? (
                <>
                  <span className="hidden md:inline text-sm font-medium text-primary-foreground/80 whitespace-nowrap leading-none">
                    {user.username}
                  </span>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1.5 rounded-lg border border-primary-foreground/25 bg-primary-foreground/5 px-4 py-2 text-sm font-semibold text-primary-foreground transition-all hover:bg-primary-foreground/10 whitespace-nowrap leading-none"
                    onClick={() => void logout().then(() => toast.success("Signed out."))}
                  >
                    Sign out
                  </button>
                </>
              ) : (
                <>
                  <button
                    type="button"
                    className="hidden md:inline-flex text-sm font-medium text-primary-foreground/80 hover:text-primary-foreground transition-colors whitespace-nowrap leading-none"
                    onClick={() => {
                      setAuthMode("signin");
                      setAuthOpen(true);
                    }}
                  >
                    Sign In
                  </button>
                  <button
                    type="button"
                    className="inline-flex items-center gap-1.5 rounded-lg bg-emerald px-4 py-2 text-sm font-semibold text-primary-foreground transition-all hover:bg-emerald-light shadow-md hover:shadow-glow whitespace-nowrap leading-none"
                    onClick={() => {
                      setAuthMode("signup");
                      setAuthOpen(true);
                    }}
                  >
                    Get Started <ChevronRight className="h-3.5 w-3.5" />
                  </button>
                </>
              )}
            </div>

            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle>
                  {authMode === "signin" ? "Sign in to Starting XI" : "Create your Starting XI profile"}
                </DialogTitle>
                <DialogDescription>
                  {authMode === "signin"
                    ? "Access your saved profiles, division-fit reports, and recommendations."
                    : "Create an account with a username and password. Your session is stored securely via the API."}
                </DialogDescription>
              </DialogHeader>

              <div className="mb-4 inline-flex rounded-full bg-muted p-1 text-xs font-semibold">
                <button
                  type="button"
                  onClick={() => setAuthMode("signin")}
                  className={`flex-1 px-3 py-1 rounded-full transition-colors ${
                    authMode === "signin" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
                  }`}
                >
                  Sign In
                </button>
                <button
                  type="button"
                  onClick={() => setAuthMode("signup")}
                  className={`flex-1 px-3 py-1 rounded-full transition-colors ${
                    authMode === "signup" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground"
                  }`}
                >
                  Sign Up
                </button>
              </div>

              <form className="space-y-4" onSubmit={handleAuthSubmit}>
                {authMode === "signup" && (
                  <div className="space-y-1">
                    <label className="text-xs font-medium text-muted-foreground" htmlFor="grad-year">
                      Grad year (optional)
                    </label>
                    <input
                      id="grad-year"
                      type="text"
                      inputMode="numeric"
                      autoComplete="off"
                      value={gradYear}
                      onChange={(e) => setGradYear(e.target.value)}
                      className="w-full rounded-md border border-border bg-background px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-emerald focus-visible:ring-offset-0"
                      placeholder="2027"
                    />
                  </div>
                )}

                <div className="space-y-1">
                  <label className="text-xs font-medium text-muted-foreground" htmlFor="auth-username">
                    Username
                  </label>
                  <input
                    id="auth-username"
                    type="text"
                    autoComplete="username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    className="w-full rounded-md border border-border bg-background px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-emerald focus-visible:ring-offset-0"
                    placeholder="your_username"
                  />
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-medium text-muted-foreground" htmlFor="auth-password">
                    Password
                  </label>
                  <input
                    id="auth-password"
                    type="password"
                    autoComplete={authMode === "signup" ? "new-password" : "current-password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full rounded-md border border-border bg-background px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-emerald focus-visible:ring-offset-0"
                    placeholder="••••••••"
                  />
                </div>

                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="mt-2 inline-flex w-full items-center justify-center rounded-md bg-emerald px-4 py-2.5 text-sm font-semibold text-primary-foreground shadow-md transition-colors hover:bg-emerald-light disabled:opacity-60 disabled:pointer-events-none"
                >
                  {isSubmitting ? "Please wait…" : authMode === "signin" ? "Continue" : "Create account"}
                </button>

                <p className="text-[11px] text-muted-foreground leading-relaxed">
                  Accounts are created on the Django API (session cookies). Use the same machine with the dev server
                  proxy, or set <code className="text-[10px]">VITE_API_BASE_URL</code> to your API origin. Athletic and
                  academic details are used only to generate guidance and are not shared with schools without your
                  consent.
                </p>
              </form>
            </DialogContent>
          </Dialog>
        </div>
      </header>

      <section className="relative min-h-screen gradient-hero overflow-hidden flex items-center">
        {/* Grid overlay */}
        <div
          className="absolute inset-0 opacity-[0.04]"
          style={{
            backgroundImage:
              "linear-gradient(hsl(var(--primary-foreground)) 1px, transparent 1px), linear-gradient(90deg, hsl(var(--primary-foreground)) 1px, transparent 1px)",
            backgroundSize: "48px 48px",
          }}
        />

        {/* Radial glow */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[600px] w-[600px] rounded-full bg-emerald/10 blur-[120px] pointer-events-none" />

        <div className="container relative mx-auto px-6 py-32 text-center">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 rounded-full border border-emerald/30 bg-emerald/10 px-4 py-1.5 mb-8 animate-fade-in">
            <Zap className="h-3.5 w-3.5 text-emerald-light" />
            <span className="text-xs font-semibold uppercase tracking-widest text-emerald-light">
              Collegiate Soccer Benchmarking
            </span>
          </div>

          <h1 className="mx-auto max-w-4xl text-5xl md:text-7xl font-bold text-primary-foreground leading-[1.08] tracking-tight animate-fade-up" style={{ animationDelay: "0.1s" }}>
            Know Exactly Where
            <br />
            <span className="text-emerald-light">You Stand</span>
          </h1>

          <p className="mx-auto mt-6 max-w-2xl text-lg md:text-xl text-primary-foreground/60 leading-relaxed animate-fade-up" style={{ animationDelay: "0.2s" }}>
            Compare your stats to NCAA D1, D2, and D3 benchmarks by position. Use it alongside other recruiting tools to see where you stand.
          </p>

          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4 animate-fade-up" style={{ animationDelay: "0.3s" }}>
            <button className="inline-flex items-center gap-2 rounded-xl bg-emerald px-8 py-4 text-base font-bold text-primary-foreground transition-all hover:bg-emerald-light hover:shadow-glow shadow-lg">
              Analyze My Profile <ArrowRight className="h-4 w-4" />
            </button>
            <button className="inline-flex items-center gap-2 rounded-xl border border-primary-foreground/20 bg-primary-foreground/5 px-8 py-4 text-base font-semibold text-primary-foreground/80 backdrop-blur-sm transition-all hover:bg-primary-foreground/10 hover:border-primary-foreground/30">
              See How It Works
            </button>
          </div>

          {/* Stats strip */}
          <div className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-px border border-primary-foreground/10 rounded-2xl overflow-hidden animate-fade-up" style={{ animationDelay: "0.45s" }}>
            {STATS.map((s, i) => (
              <div key={i} className="bg-primary-foreground/5 backdrop-blur-sm px-6 py-6 text-center">
                <div className="text-3xl font-bold text-emerald-light">{s.value}</div>
                <div className="mt-1 text-xs font-medium text-primary-foreground/50 uppercase tracking-wider">{s.label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom fade */}
        <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-background to-transparent" />
      </section>

      <section id="features" className="py-28 bg-background">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-xs font-semibold uppercase tracking-widest text-emerald mb-3">What We Measure</p>
            <h2 className="text-4xl md:text-5xl font-bold text-foreground leading-tight">
              Data-Driven. Position-Aware.
              <br />
              Division-Aligned.
            </h2>
            <p className="mt-5 max-w-xl mx-auto text-muted-foreground text-lg">
              Metrics are mapped to real D1/D2/D3 benchmarks by position.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {FEATURES.map((f, i) => (
              <div
                key={i}
                className="group relative rounded-2xl border border-border bg-card p-7 transition-all hover:border-emerald/40 hover:shadow-card"
              >
                <div className="mb-5 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-emerald/10 text-emerald group-hover:bg-emerald group-hover:text-primary-foreground transition-colors">
                  <f.icon className="h-5 w-5" />
                </div>
                <h3 className="text-lg font-bold text-foreground mb-2">{f.title}</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="how-it-works" className="py-28 gradient-hero relative overflow-hidden">
        <div className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage: "radial-gradient(circle at 1px 1px, hsl(var(--primary-foreground)) 1px, transparent 0)",
            backgroundSize: "32px 32px",
          }}
        />

        <div className="container relative mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-xs font-semibold uppercase tracking-widest text-emerald-light mb-3">Simple Process</p>
            <h2 className="text-4xl md:text-5xl font-bold text-primary-foreground leading-tight">
              From Raw Data to
              <br />
              Recruiting Clarity
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {HOW_IT_WORKS.map((step, i) => (
              <div key={i} className="relative">
                {i < HOW_IT_WORKS.length - 1 && (
                  <div className="hidden md:block absolute top-8 left-[calc(100%-1rem)] w-8 h-px border-t border-dashed border-emerald/30 z-10" />
                )}
                <div className="rounded-2xl border border-primary-foreground/10 bg-primary-foreground/5 backdrop-blur-sm p-8">
                  <div className="text-5xl font-black text-emerald/30 mb-4 leading-none">{step.step}</div>
                  <h3 className="text-xl font-bold text-primary-foreground mb-3">{step.title}</h3>
                  <p className="text-sm text-primary-foreground/60 leading-relaxed">{step.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-28 bg-background border-t border-border/40">
        <div className="container mx-auto px-6">
          <div className="text-center mb-14">
            <p className="text-xs font-semibold uppercase tracking-widest text-emerald mb-3">Why This Exists</p>
            <h2 className="text-4xl md:text-5xl font-bold text-foreground leading-tight">
              Built for Fit,
              <br />
              Not Just Visibility.
            </h2>
            <p className="mt-5 max-w-2xl mx-auto text-muted-foreground text-lg">
              Only a small percentage of high school athletes ever play in college, and even fewer reach Division I.
              Existing tools focus on exposure and messaging; Starting XI focuses on helping players and coaches quickly
              see whether there is a realistic athletic and academic fit.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
            <div className="rounded-2xl border border-border bg-card p-8">
              <h3 className="text-xl font-bold text-foreground mb-3">For High School Players & Families</h3>
              <ul className="space-y-3 text-sm text-muted-foreground">
                <li className="flex gap-2">
                  <CheckCircle className="h-4 w-4 text-emerald mt-0.5 flex-shrink-0" />
                  <span>Understand where your current measurables line up against D1, D2, and D3 expectations.</span>
                </li>
                <li className="flex gap-2">
                  <CheckCircle className="h-4 w-4 text-emerald mt-0.5 flex-shrink-0" />
                  <span>Use projected division fit and recommended programs as a starting point before reaching out on platforms like SportsRecruits or NCSA.</span>
                </li>
                <li className="flex gap-2">
                  <CheckCircle className="h-4 w-4 text-emerald mt-0.5 flex-shrink-0" />
                  <span>See which categories (speed, endurance, technical, academics) most need attention before your next showcase or camp.</span>
                </li>
              </ul>
            </div>

            <div className="rounded-2xl border border-border bg-card p-8">
              <h3 className="text-xl font-bold text-foreground mb-3">For College Coaches</h3>
              <ul className="space-y-3 text-sm text-muted-foreground">
                <li className="flex gap-2">
                  <CheckCircle className="h-4 w-4 text-emerald mt-0.5 flex-shrink-0" />
                  <span>Filter prospective athletes using standardized benchmarks before investing time in film review or outreach.</span>
                </li>
                <li className="flex gap-2">
                  <CheckCircle className="h-4 w-4 text-emerald mt-0.5 flex-shrink-0" />
                  <span>Quickly identify players whose measurables meet your baseline standards by position and role.</span>
                </li>
                <li className="flex gap-2">
                  <CheckCircle className="h-4 w-4 text-emerald mt-0.5 flex-shrink-0" />
                  <span>Use Starting XI as a supplemental decision-support layer on top of existing recruiting and communication platforms.</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      <section id="divisions" className="py-28 bg-background">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-xs font-semibold uppercase tracking-widest text-emerald mb-3">Benchmark Tiers</p>
            <h2 className="text-4xl md:text-5xl font-bold text-foreground leading-tight">
              Three Divisions.
              <br />
              One Clear Picture.
            </h2>
            <p className="mt-5 max-w-xl mx-auto text-muted-foreground">
              We benchmark your data against NCAA D1, D2, and D3 standards so you know which level aligns with your current profile.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {DIVISIONS.map((div, i) => (
              <div
                key={i}
                className={`rounded-2xl border p-8 relative overflow-hidden transition-all hover:shadow-card ${
                  i === 0
                    ? "border-emerald/40 bg-emerald/5"
                    : i === 1
                    ? "border-gold/30 bg-gold/5"
                    : "border-border bg-card"
                }`}
              >
                {i === 0 && (
                  <div className="absolute top-0 right-0 bg-emerald text-primary-foreground text-xs font-bold px-3 py-1 rounded-bl-xl">
                    Most Competitive
                  </div>
                )}
                <div
                  className={`text-xs font-bold uppercase tracking-widest mb-2 ${
                    i === 0 ? "text-emerald" : i === 1 ? "text-gold" : "text-muted-foreground"
                  }`}
                >
                  {div.tagline}
                </div>
                <h3 className="text-2xl font-black text-foreground mb-3">{div.label}</h3>
                <p className="text-sm text-muted-foreground leading-relaxed mb-6">{div.desc}</p>
                <ul className="space-y-2">
                  {div.highlights.map((h, j) => (
                    <li key={j} className="flex items-center gap-2 text-sm text-foreground">
                      <CheckCircle
                        className={`h-4 w-4 flex-shrink-0 ${
                          i === 0 ? "text-emerald" : i === 1 ? "text-gold" : "text-muted-foreground"
                        }`}
                      />
                      {h}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-28 gradient-hero relative overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[500px] w-[500px] rounded-full bg-emerald/10 blur-[100px] pointer-events-none" />
        <div className="container relative mx-auto px-6 text-center">
          <Award className="mx-auto h-12 w-12 text-emerald mb-6" />
          <h2 className="text-4xl md:text-5xl font-bold text-primary-foreground mb-5 leading-tight">
            Stop Guessing. Start
            <br />
            <span className="text-emerald-light">Benchmarking.</span>
          </h2>
          <p className="text-primary-foreground/60 text-lg max-w-lg mx-auto mb-10">
            Create a profile and get your division fit report. Free. Use it with other recruiting tools to narrow down programs.
          </p>
          <button className="inline-flex items-center gap-2 rounded-xl bg-emerald px-10 py-4 text-base font-bold text-primary-foreground transition-all hover:bg-emerald-light hover:shadow-glow shadow-xl">
            Create My Profile — It's Free <ArrowRight className="h-4 w-4" />
          </button>
          <p className="mt-4 text-xs text-primary-foreground/30">
            Results presented as guidance only. Not affiliated with or endorsed by the NCAA.
          </p>
        </div>
      </section>

      <footer className="border-t border-border bg-background py-12">
        <div className="container mx-auto px-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-2">
              <div className="flex h-7 w-7 items-center justify-center rounded-md bg-emerald">
                <span className="text-xs font-bold text-primary-foreground">XI</span>
              </div>
              <span className="font-bold text-foreground">Starting XI</span>
            </div>
            <p className="text-xs text-muted-foreground text-center">
              © 2026 Starting XI. Benchmarks for informational use only. Not endorsed by the NCAA.
            </p>
            <div className="flex gap-6">
              {["Privacy", "Terms", "Contact"].map((l) => (
                <a key={l} href="#" className="text-xs text-muted-foreground hover:text-foreground transition-colors">
                  {l}
                </a>
              ))}
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
