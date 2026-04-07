import { ArrowRight, Zap } from "lucide-react";
import { STATS } from "@/constants/landing";

export function Hero() {
  return (
    <section className="relative min-h-screen gradient-hero overflow-hidden flex items-center">
      <div
        className="absolute inset-0 opacity-[0.04]"
        style={{
          backgroundImage:
            "linear-gradient(hsl(var(--primary-foreground)) 1px, transparent 1px), linear-gradient(90deg, hsl(var(--primary-foreground)) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[600px] w-[600px] rounded-full bg-emerald/10 blur-[120px] pointer-events-none" />

      <div className="container relative mx-auto px-6 py-32 text-center">
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
          Starting XI translates your athletic and academic data into objective, division-aligned recruiting insight — so high school soccer players can stop guessing and start preparing.
        </p>

        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4 animate-fade-up" style={{ animationDelay: "0.3s" }}>
          <button className="inline-flex items-center gap-2 rounded-xl bg-emerald px-8 py-4 text-base font-bold text-primary-foreground transition-all hover:bg-emerald-light hover:shadow-glow shadow-lg">
            Analyze My Profile <ArrowRight className="h-4 w-4" />
          </button>
          <button className="inline-flex items-center gap-2 rounded-xl border border-primary-foreground/20 bg-primary-foreground/5 px-8 py-4 text-base font-semibold text-primary-foreground/80 backdrop-blur-sm transition-all hover:bg-primary-foreground/10 hover:border-primary-foreground/30">
            See How It Works
          </button>
        </div>

        <div className="mt-20 grid grid-cols-2 md:grid-cols-4 gap-px border border-primary-foreground/10 rounded-2xl overflow-hidden animate-fade-up" style={{ animationDelay: "0.45s" }}>
          {STATS.map((s, i) => (
            <div key={i} className="bg-primary-foreground/5 backdrop-blur-sm px-6 py-6 text-center">
              <div className="text-3xl font-bold text-emerald-light">{s.value}</div>
              <div className="mt-1 text-xs font-medium text-primary-foreground/50 uppercase tracking-wider">{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-background to-transparent" />
    </section>
  );
}
