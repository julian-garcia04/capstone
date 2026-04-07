import { useState } from "react";
import { Link } from "react-router-dom";
import { ChevronLeft, Star, Trophy, MapPin, Ruler, Weight, Calendar, Play } from "lucide-react";

// todo: replace with API/CMS
const PLAYER = {
  name: "Jayden Carter",
  position: "Forward / Winger",
  school: "Lincoln High School — Class of 2026",
  location: "Atlanta, GA",
  age: 17,
  height: "5'11\"",
  weight: "165 lbs",
  gpa: "3.8",
  photo: "https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?w=600&h=700&fit=crop&crop=face",
  video: "https://www.youtube.com/embed/dQw4w9WgXcQ",
  stats: [
    { label: "Goals This Season", value: "22" },
    { label: "Assists", value: "11" },
    { label: "40-Yard Dash", value: "4.52s" },
    { label: "Beep Test Level", value: "13.2" },
    { label: "T-Test Agility", value: "9.1s" },
    { label: "Vertical Jump", value: '28"' },
  ],
  highlights: [
    "2x All-Region Selection",
    "State Tournament MVP 2025",
    "Team Captain — 2 consecutive seasons",
    "Olympic Development Program invitee",
  ],
  quote: "I want to compete at the highest level. Hard work and good preparation close the gap.",
};

export default function StarPlayer() {
  const [videoPlaying, setVideoPlaying] = useState(false);

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
            <Link to="/star-player" className="text-sm font-medium text-emerald-light transition-colors">Star Player</Link>
            <Link to="/recruitments" className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors">Recruitments</Link>
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

          <div className="flex items-center gap-3 mb-4">
            <Star className="h-5 w-5 text-gold fill-gold" />
            <span className="text-xs font-bold uppercase tracking-widest text-gold">Star Player of the Month</span>
            <Star className="h-5 w-5 text-gold fill-gold" />
          </div>
          <h1 className="text-4xl md:text-6xl font-bold text-primary-foreground leading-tight">{PLAYER.name}</h1>
          <p className="text-lg text-primary-foreground/60 mt-2">{PLAYER.position}</p>
        </div>
        <div className="absolute bottom-0 left-0 right-0 h-24 bg-gradient-to-t from-background to-transparent" />
      </section>

      <section className="py-16 bg-background">
        <div className="container mx-auto px-6">
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-10">
            {/* Photo + Info */}
            <div className="lg:col-span-2 space-y-6">
              <div className="rounded-2xl overflow-hidden border border-border shadow-card">
                <img
                  src={PLAYER.photo}
                  alt={`${PLAYER.name} — Star Player of the Month`}
                  className="w-full h-[420px] object-cover"
                />
              </div>

              {/* Quick Info */}
              <div className="rounded-2xl border border-border bg-card p-6 space-y-4">
                <h3 className="text-sm font-bold uppercase tracking-widest text-emerald">Player Info</h3>
                <div className="space-y-3">
                  {[
                    { icon: MapPin, label: PLAYER.location },
                    { icon: Calendar, label: `Age ${PLAYER.age} — ${PLAYER.school}` },
                    { icon: Ruler, label: `${PLAYER.height} / ${PLAYER.weight}` },
                    { icon: Trophy, label: `GPA: ${PLAYER.gpa}` },
                  ].map((item, i) => (
                    <div key={i} className="flex items-center gap-3 text-sm text-foreground">
                      <item.icon className="h-4 w-4 text-emerald flex-shrink-0" />
                      {item.label}
                    </div>
                  ))}
                </div>
              </div>

              {/* Highlights */}
              <div className="rounded-2xl border border-border bg-card p-6 space-y-4">
                <h3 className="text-sm font-bold uppercase tracking-widest text-emerald">Achievements</h3>
                <ul className="space-y-2">
                  {PLAYER.highlights.map((h, i) => (
                    <li key={i} className="flex items-start gap-2 text-sm text-foreground">
                      <Star className="h-3.5 w-3.5 text-gold fill-gold mt-0.5 flex-shrink-0" />
                      {h}
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            {/* Video + Stats */}
            <div className="lg:col-span-3 space-y-8">
              {/* Video */}
              <div>
                <h2 className="text-sm font-bold uppercase tracking-widest text-emerald mb-4">Highlight Reel</h2>
                <div className="rounded-2xl overflow-hidden border border-border shadow-card bg-navy aspect-video relative">
                  {!videoPlaying ? (
                    <div
                      className="absolute inset-0 flex flex-col items-center justify-center cursor-pointer group"
                      onClick={() => setVideoPlaying(true)}
                    >
                      <div className="absolute inset-0 bg-gradient-to-b from-navy/60 to-navy/90" />
                      <img src={PLAYER.photo} alt="" className="absolute inset-0 w-full h-full object-cover opacity-30" />
                      <div className="relative z-10 flex flex-col items-center gap-4">
                        <div className="h-20 w-20 rounded-full bg-emerald/90 flex items-center justify-center shadow-glow group-hover:bg-emerald transition-colors">
                          <Play className="h-8 w-8 text-primary-foreground ml-1" />
                        </div>
                        <span className="text-sm font-semibold text-primary-foreground/80">Watch Highlights</span>
                      </div>
                    </div>
                  ) : (
                    <iframe
                      src={`${PLAYER.video}?autoplay=1`}
                      title="Player Highlights"
                      className="w-full h-full"
                      allow="autoplay; encrypted-media"
                      allowFullScreen
                    />
                  )}
                </div>
              </div>

              {/* Stats Grid */}
              <div>
                <h2 className="text-sm font-bold uppercase tracking-widest text-emerald mb-4">Key Metrics</h2>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                  {PLAYER.stats.map((s, i) => (
                    <div key={i} className="rounded-xl border border-border bg-card p-5 text-center transition-all hover:border-emerald/30 hover:shadow-card">
                      <div className="text-2xl font-black text-foreground">{s.value}</div>
                      <div className="text-xs text-muted-foreground mt-1 uppercase tracking-wider">{s.label}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Quote */}
              <div className="rounded-2xl border border-emerald/20 bg-emerald/5 p-8">
                <div className="text-3xl text-emerald/40 font-serif leading-none mb-3">"</div>
                <p className="text-lg text-foreground leading-relaxed italic">{PLAYER.quote}</p>
                <p className="mt-4 text-sm font-bold text-emerald">— {PLAYER.name}</p>
              </div>
            </div>
          </div>
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
