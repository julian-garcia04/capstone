import { CheckCircle } from "lucide-react";
import { DIVISIONS } from "@/constants/landing";

export function Divisions() {
  return (
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
  );
}
