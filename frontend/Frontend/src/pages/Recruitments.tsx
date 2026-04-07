import { Link } from "react-router-dom";
import { ChevronLeft, MapPin, GraduationCap, Clock, ExternalLink, Filter } from "lucide-react";
import { useState } from "react";

type Division = "All" | "D1" | "D2" | "D3";

const RECRUITMENTS = [
  {
    school: "University of North Carolina",
    division: "D1" as const,
    location: "Chapel Hill, NC",
    position: "Forward",
    deadline: "March 15, 2026",
    status: "Open",
    scholarship: "Full Athletic",
    desc: "Looking for dynamic attackers with elite speed metrics and strong academics. Must have a Beep Test level of 12+ and sub-4.6 40-yard dash.",
  },
  {
    school: "Wake Forest University",
    division: "D1" as const,
    location: "Winston-Salem, NC",
    position: "Midfielder",
    deadline: "April 1, 2026",
    status: "Open",
    scholarship: "Full Athletic",
    desc: "Seeking well-rounded midfielders with high endurance (Yo-Yo IR1 Level 19+) and strong passing vision. GPA 3.5+ preferred.",
  },
  {
    school: "Rollins College",
    division: "D2" as const,
    location: "Winter Park, FL",
    position: "Defender / Midfielder",
    deadline: "May 1, 2026",
    status: "Open",
    scholarship: "Partial Athletic",
    desc: "Competitive program looking for versatile players with solid agility (T-Test under 9.5s) and leadership qualities.",
  },
  {
    school: "University of Tampa",
    division: "D2" as const,
    location: "Tampa, FL",
    position: "Goalkeeper",
    deadline: "March 30, 2026",
    status: "Open",
    scholarship: "Partial Athletic",
    desc: "Need athletic goalkeeper with excellent reaction time, vertical jump 26\"+, and strong communication skills.",
  },
  {
    school: "Emory University",
    division: "D3" as const,
    location: "Atlanta, GA",
    position: "Any Position",
    deadline: "Rolling",
    status: "Open",
    scholarship: "Academic Merit",
    desc: "Highly selective academics with a strong soccer tradition. Looking for student-athletes with GPA 3.7+ and well-rounded fitness profiles.",
  },
  {
    school: "Johns Hopkins University",
    division: "D3" as const,
    location: "Baltimore, MD",
    position: "Forward / Winger",
    deadline: "Rolling",
    status: "Open",
    scholarship: "Academic Merit",
    desc: "Competitive D3 program seeking quick attackers. Value strong academics alongside athletic measurables.",
  },
];

const DIVISION_COLORS: Record<string, string> = {
  D1: "bg-emerald/10 text-emerald border-emerald/30",
  D2: "bg-gold/10 text-gold border-gold/30",
  D3: "bg-muted text-muted-foreground border-border",
};

export default function Recruitments() {
  const [filter, setFilter] = useState<Division>("All");

  const filtered = filter === "All" ? RECRUITMENTS : RECRUITMENTS.filter((r) => r.division === filter);

  return (
    <div className="min-h-screen bg-background font-sans antialiased">
      <header className="fixed top-0 left-0 right-0 z-50 bg-navy/95 backdrop-blur-md shadow-lg">
        <div className="container mx-auto flex h-16 items-center justify-between px-6">
          <Link to="/" className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-md bg-emerald">
              <span className="text-sm font-bold text-primary-foreground">XI</span>
            </div>
            <span className="text-lg font-bold tracking-tight text-primary-foreground">Starting XI</span>
          </Link>
          <nav className="hidden md:flex items-center gap-6">
            <Link to="/" className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors">Home</Link>
            <Link to="/star-player" className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors">Star Player</Link>
            <Link to="/recruitments" className="text-sm font-medium text-emerald-light transition-colors">Recruitments</Link>
            <Link to="/profile" className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors">My profile</Link>
          </nav>
        </div>
      </header>

      <section className="pt-16 gradient-hero relative overflow-hidden">
        <div className="absolute inset-0 opacity-[0.03]" style={{ backgroundImage: "radial-gradient(circle at 1px 1px, hsl(var(--primary-foreground)) 1px, transparent 0)", backgroundSize: "32px 32px" }} />
        <div className="container relative mx-auto px-6 py-16 md:py-24">
          <Link to="/" className="inline-flex items-center gap-1.5 text-sm text-primary-foreground/50 hover:text-primary-foreground/80 transition-colors mb-8">
            <ChevronLeft className="h-4 w-4" /> Back to Home
          </Link>
          <h1 className="text-4xl md:text-6xl font-bold text-primary-foreground leading-tight">
            Current <span className="text-emerald-light">Recruitments</span>
          </h1>
          <p className="text-lg text-primary-foreground/60 mt-3 max-w-2xl">
            Browse active collegiate soccer recruitment opportunities across NCAA Divisions I, II, and III.
          </p>
        </div>
        <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-background to-transparent" />
      </section>

      {/* Filters + Listings */}
      <section className="py-16 bg-background">
        <div className="container mx-auto px-6">
          {/* Filter Bar */}
          <div className="flex flex-wrap items-center gap-3 mb-10">
            <Filter className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm font-medium text-muted-foreground mr-2">Filter:</span>
            {(["All", "D1", "D2", "D3"] as Division[]).map((d) => (
              <button
                key={d}
                onClick={() => setFilter(d)}
                className={`rounded-full px-4 py-1.5 text-sm font-semibold border transition-all ${
                  filter === d
                    ? "bg-emerald text-primary-foreground border-emerald"
                    : "bg-card text-foreground border-border hover:border-emerald/40"
                }`}
              >
                {d === "All" ? "All Divisions" : d}
              </button>
            ))}
          </div>

          {/* Listings */}
          <div className="space-y-5">
            {filtered.map((r, i) => (
              <div
                key={i}
                className="rounded-2xl border border-border bg-card p-6 md:p-8 transition-all hover:border-emerald/30 hover:shadow-card"
              >
                <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
                  <div className="flex-1">
                    <div className="flex flex-wrap items-center gap-3 mb-2">
                      <h3 className="text-xl font-bold text-foreground">{r.school}</h3>
                      <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-bold ${DIVISION_COLORS[r.division]}`}>
                        {r.division}
                      </span>
                      <span className="inline-flex items-center rounded-full bg-emerald/10 text-emerald border border-emerald/20 px-2.5 py-0.5 text-xs font-semibold">
                        {r.status}
                      </span>
                    </div>

                    <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground mb-3">
                      <span className="flex items-center gap-1"><MapPin className="h-3.5 w-3.5" />{r.location}</span>
                      <span className="flex items-center gap-1"><GraduationCap className="h-3.5 w-3.5" />{r.scholarship}</span>
                      <span className="flex items-center gap-1"><Clock className="h-3.5 w-3.5" />Deadline: {r.deadline}</span>
                    </div>

                    <p className="text-sm text-foreground/80 leading-relaxed mb-1">
                      <span className="font-semibold text-emerald">Position:</span> {r.position}
                    </p>
                    <p className="text-sm text-muted-foreground leading-relaxed">{r.desc}</p>
                  </div>

                  <button className="inline-flex items-center gap-1.5 rounded-lg bg-emerald/10 border border-emerald/20 px-4 py-2.5 text-sm font-semibold text-emerald hover:bg-emerald hover:text-primary-foreground transition-all flex-shrink-0">
                    View Details <ExternalLink className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>

          {filtered.length === 0 && (
            <div className="text-center py-20">
              <p className="text-muted-foreground">No recruitments found for this filter.</p>
            </div>
          )}
        </div>
      </section>

      <footer className="border-t border-border bg-background py-10">
        <div className="container mx-auto px-6 text-center">
          <p className="text-xs text-muted-foreground">© 2026 Starting XI. Benchmarks for informational use only. Not endorsed by the NCAA.</p>
        </div>
      </footer>
    </div>
  );
}
