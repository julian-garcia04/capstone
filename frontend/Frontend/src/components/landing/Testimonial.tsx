import { Users } from "lucide-react";
import { TESTIMONIAL } from "@/constants/landing";

export function Testimonial() {
  return (
    <section className="py-24 bg-muted/40">
      <div className="container mx-auto px-6">
        <div className="max-w-3xl mx-auto text-center">
          <div className="text-4xl text-emerald/40 font-serif mb-6 leading-none">"</div>
          <blockquote className="text-xl md:text-2xl font-medium text-foreground leading-relaxed mb-8">
            {TESTIMONIAL.quote}
          </blockquote>
          <div className="flex items-center justify-center gap-3">
            <div className="h-10 w-10 rounded-full bg-emerald/20 flex items-center justify-center">
              <Users className="h-5 w-5 text-emerald" />
            </div>
            <div className="text-left">
              <div className="text-sm font-bold text-foreground">{TESTIMONIAL.name}</div>
              <div className="text-xs text-muted-foreground">{TESTIMONIAL.info}</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
