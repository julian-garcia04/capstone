import { ChevronRight } from "lucide-react";
import { NAV_LINKS } from "@/constants/landing";

interface HeaderProps {
  scrolled: boolean;
}

export function Header({ scrolled }: HeaderProps) {
  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        scrolled ? "bg-navy/95 backdrop-blur-md shadow-lg" : "bg-transparent"
      }`}
    >
      <div className="container mx-auto flex h-16 items-center justify-between px-6">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-md bg-emerald">
            <span className="text-sm font-bold text-primary-foreground">XI</span>
          </div>
          <span className="text-lg font-bold tracking-tight text-primary-foreground">Starting XI</span>
        </div>

        <nav className="hidden md:flex items-center gap-8">
          {NAV_LINKS.map((link) => (
            <a
              key={link}
              href={`#${link.toLowerCase().replace(" ", "-")}`}
              className="text-sm font-medium text-primary-foreground/70 transition-colors hover:text-primary-foreground"
            >
              {link}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <button className="hidden md:inline-flex text-sm font-medium text-primary-foreground/80 hover:text-primary-foreground transition-colors">
            Sign In
          </button>
          <button className="inline-flex items-center gap-1.5 rounded-lg bg-emerald px-4 py-2 text-sm font-semibold text-primary-foreground transition-all hover:bg-emerald-light shadow-md hover:shadow-glow">
            Get Started <ChevronRight className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>
    </header>
  );
}
