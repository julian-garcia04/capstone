import { FOOTER_LINKS } from "@/constants/landing";

export function Footer() {
  return (
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
            {FOOTER_LINKS.map((l) => (
              <a key={l} href="#" className="text-xs text-muted-foreground hover:text-foreground transition-colors">
                {l}
              </a>
            ))}
          </div>
        </div>
      </div>
    </footer>
  );
}
