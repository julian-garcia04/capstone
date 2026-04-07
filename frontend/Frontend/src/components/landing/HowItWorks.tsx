import { HOW_IT_WORKS } from "@/constants/landing";

export function HowItWorks() {
  return (
    <section id="how-it-works" className="py-28 gradient-hero relative overflow-hidden">
      <div
        className="absolute inset-0 opacity-[0.03]"
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
  );
}
