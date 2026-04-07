import { Award, ArrowRight } from "lucide-react";

export function Cta() {
  return (
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
          Create a profile and get your division fit report. Free.
        </p>
        <button className="inline-flex items-center gap-2 rounded-xl bg-emerald px-10 py-4 text-base font-bold text-primary-foreground transition-all hover:bg-emerald-light hover:shadow-glow shadow-xl">
          Create My Profile — It's Free <ArrowRight className="h-4 w-4" />
        </button>
        <p className="mt-4 text-xs text-primary-foreground/30">
          Results presented as guidance only. Not affiliated with or endorsed by the NCAA.
        </p>
      </div>
    </section>
  );
}
