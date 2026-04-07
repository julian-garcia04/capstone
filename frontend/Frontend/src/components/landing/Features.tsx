import { FEATURES } from "@/constants/landing";

export function Features() {
  return (
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
            Every metric is mapped to real division benchmarks, not generic athletic averages.
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
  );
}
