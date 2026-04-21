import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { ChevronLeft, ClipboardList, Loader2, RefreshCw, Sparkles } from "lucide-react";
import { toast } from "sonner";
import { useAuth } from "@/contexts/AuthContext";
import { fetchFitReport, submitAthleteTest, type FitReport, type AthleteTest } from "@/lib/api";
import {
  ALL_TEST_KEYS,
  TEST_FIELD_GROUPS,
  TEST_FIELD_LABELS,
  formatAthleteTestMetric,
  testFieldLabelWithUnit,
  type TestFieldKey,
} from "@/constants/athleteTests";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

function emptyTestForm(): Record<TestFieldKey, string> {
  return Object.fromEntries(ALL_TEST_KEYS.map((k) => [k, ""])) as Record<TestFieldKey, string>;
}

function summarizeTest(t: AthleteTest): string {
  const parts: string[] = [];
  for (const key of ALL_TEST_KEYS) {
    const v = t[key];
    if (v == null || v === "") continue;
    const withUnit = formatAthleteTestMetric(key, v as string | number);
    if (withUnit) parts.push(`${TEST_FIELD_LABELS[key]}: ${withUnit}`);
  }
  return parts.length ? parts.join(" · ") : "—";
}

export default function Profile() {
  const { user, isBootstrapping, updateProfile, refreshSession, isSubmitting } = useAuth();
  const [gradYear, setGradYear] = useState("");
  const [heightIn, setHeightIn] = useState("");
  const [weightLb, setWeightLb] = useState("");
  const [testForm, setTestForm] = useState(emptyTestForm);
  const [savingTest, setSavingTest] = useState(false);
  const [fitLoading, setFitLoading] = useState(false);
  const [fitReport, setFitReport] = useState<FitReport | null>(null);
  const [fitError, setFitError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    setGradYear(user.grad_year != null ? String(user.grad_year) : "");
    setHeightIn(user.height_in != null ? String(user.height_in) : "");
    setWeightLb(user.weight_lb != null ? String(user.weight_lb) : "");
  }, [user]);

  const testsSorted = useMemo(() => {
    if (!user?.tests?.length) return [];
    return [...user.tests].sort((a, b) => {
      const da = a.test_date ?? "";
      const db = b.test_date ?? "";

      // 1. Sort by date first
      if (da !== db) {
        return db.localeCompare(da);
      }
      // 2. TIE-BREAKER: If it's the same day, put the newest database ID on top
      return (b.id ?? 0) - (a.id ?? 0);
    });
  }, [user?.tests]);

  const handleSaveProfile = async (e: FormEvent) => {
    e.preventDefault();
    try {
      await updateProfile({
        grad_year: gradYear.trim() ? parseInt(gradYear, 10) : null,
        height_in: heightIn.trim() ? parseFloat(heightIn) : null,
        weight_lb: weightLb.trim() ? parseFloat(weightLb) : null,
      });
      toast.success("Profile saved.");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Could not save profile.");
    }
  };

  const handleLogTest = async (e: FormEvent) => {
  e.preventDefault();
  const metrics: Partial<Record<TestFieldKey, number>> = {};

  // 1. Carry forward previous metrics from the most recent test
  if (testsSorted.length > 0) {
    const lastTest = testsSorted[0];
    for (const key of ALL_TEST_KEYS) {
      if (lastTest[key] != null && lastTest[key] !== "") {
        metrics[key] = Number(lastTest[key]);
      }
    }
  }

  // 2. Overwrite with any new inputs from the form
  for (const key of ALL_TEST_KEYS) {
    const raw = testForm[key].trim();
    if (!raw) continue;
    const n = parseFloat(raw);
    if (Number.isNaN(n)) {
      toast.error(`Invalid number for ${TEST_FIELD_LABELS[key]}.`);
      return;
    }
    metrics[key] = n; // This overwrites the old value
  }

  setSavingTest(true);
  try {
    await submitAthleteTest(metrics);
    setTestForm(emptyTestForm());
    await refreshSession();
    toast.success("Test entry saved and merged.");
    setFitReport(null);
    setFitError(null);
  } catch (err) {
    toast.error(err instanceof Error ? err.message : "Could not save test.");
  } finally {
    setSavingTest(false);
  }
};
  const loadFitReport = useCallback(async () => {
    setFitLoading(true);
    setFitError(null);
    try {
      const report = await fetchFitReport();
      setFitReport(report);
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Could not load fit report.";
      setFitError(msg);
      setFitReport(null);
    } finally {
      setFitLoading(false);
    }
  }, []);

  // Auto-load the fit report if the user has tests!
  useEffect(() => {
    if (testsSorted.length > 0 && !fitReport && !fitLoading) {
      void loadFitReport();
    }
  }, [testsSorted, fitReport, fitLoading, loadFitReport]);

  if (isBootstrapping) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-emerald" aria-label="Loading" />
      </div>
    );
  }

  if (!user) {
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
          </div>
        </header>
        <main className="container mx-auto px-6 pt-28 pb-16 max-w-lg">
          <Card>
            <CardHeader>
              <CardTitle>Sign in to continue</CardTitle>
              <CardDescription>
                Your profile and measurables are stored on the Starting XI API. Sign in from the home page, then come
                back here.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button asChild className="bg-emerald hover:bg-emerald-light text-primary-foreground">
                <Link to="/">Back to home</Link>
              </Button>
            </CardContent>
          </Card>
        </main>
      </div>
    );
  }
const latestTest = testsSorted.length > 0 ? testsSorted[0] : {};
  const queryParams = new URLSearchParams();

  if (user) queryParams.append("user", user.username);
  if (user?.grad_year) queryParams.append("grad_year", user.grad_year.toString());
  if (user?.height_in) queryParams.append("height_in", user.height_in.toString());
  if (user?.weight_lb) queryParams.append("weight_lb", user.weight_lb.toString());

  ALL_TEST_KEYS.forEach(key => {
    if (latestTest[key] !== null && latestTest[key] !== undefined && latestTest[key] !== "") {
      queryParams.append(key, latestTest[key].toString());
    }
  });
queryParams.append("refresh", Date.now().toString());

  const shinyUrl = `http://127.0.0.1:6746/?${queryParams.toString()}`;

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
            <Link
              to="/"
              className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors"
            >
              Home
            </Link>
            <Link
              to="/star-player"
              className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors"
            >
              Star Player
            </Link>
            <Link
              to="/recruitments"
              className="text-sm font-medium text-primary-foreground/70 hover:text-primary-foreground transition-colors"
            >
              Recruitments
            </Link>
            <span className="text-sm font-medium text-emerald-light">My profile</span>
          </nav>
        </div>
      </header>

      <section className="pt-16 gradient-hero relative overflow-hidden">
        <div
          className="absolute inset-0 opacity-[0.03]"
          style={{
            backgroundImage:
              "radial-gradient(circle at 1px 1px, hsl(var(--primary-foreground)) 1px, transparent 0)",
            backgroundSize: "32px 32px",
          }}
        />
        <div className="container relative mx-auto px-6 py-12 md:py-16">
          <Link
            to="/"
            className="inline-flex items-center gap-1.5 text-sm text-primary-foreground/50 hover:text-primary-foreground/80 transition-colors mb-8"
          >
            <ChevronLeft className="h-4 w-4" /> Back to Home
          </Link>
          <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-6">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full border border-emerald/30 bg-emerald/10 px-3 py-1 mb-4">
                <ClipboardList className="h-3.5 w-3.5 text-emerald-light" />
                <span className="text-xs font-semibold uppercase tracking-widest text-emerald-light">Your data</span>
              </div>
              <h1 className="text-4xl md:text-5xl font-bold text-primary-foreground leading-tight">My profile</h1>
              <p className="mt-2 text-lg text-primary-foreground/60 max-w-2xl">
                Signed in as <span className="text-primary-foreground font-medium">{user.username}</span>. Update your
                details and log standardized tests—aligned with the division fit engine on the API.
              </p>
            </div>
          </div>
        </div>
        <div className="absolute bottom-0 left-0 right-0 h-16 bg-gradient-to-t from-background to-transparent" />
      </section>

      <main className="container mx-auto px-6 pb-20 space-y-8 mt-8">

        {/* ========================================= */}
        {/* ROW 1: THE RADAR (Full Width for R Shiny) */}
        {/* ========================================= */}
        <Card className="border-border shadow-card overflow-hidden">
          <CardHeader className="bg-gray-50/50 border-b border-gray-100 pb-4">
            <CardTitle className="text-xl">Visual Performance Radar</CardTitle>
            <CardDescription>Explore your full analytics profile below. Compare your specific metrics against division standards.</CardDescription>
          </CardHeader>
          <div className="w-full min-h-[850px]">
            <iframe
              key={shinyUrl}
              src={shinyUrl}
              style={{ width: '100%', height: '100%', minHeight: '850px', border: 'none' }}
              title="Starting XI Visual Fit Report"
            />
          </div>
        </Card>

        {/* ========================================= */}
        {/* ROW 2: FIT & DATA ENTRY                   */}
        {/* ========================================= */}
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-8">

          {/* LEFT SIDE: Division Fit (5 Columns) */}
          <div className="xl:col-span-5 flex flex-col">
            <Card className="border-border shadow-card h-full flex flex-col">
              <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                  <CardTitle className="text-xl flex items-center gap-2">
                    <Sparkles className="h-5 w-5 text-gold" />
                    Division fit
                  </CardTitle>
                  <CardDescription>
                    Uses your most recent test row and NCAA benchmarks.
                  </CardDescription>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  disabled={fitLoading}
                  onClick={() => void loadFitReport()}
                  className="border-gold/40 text-foreground hover:bg-gold/10 shrink-0"
                >
                  {fitLoading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <>
                      <RefreshCw className="h-4 w-4 mr-2" />
                      Load report
                    </>
                  )}
                </Button>
              </CardHeader>
              <CardContent className="space-y-4 flex-1">
                {fitError && (
                  <p className="text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-md px-3 py-2">
                    {fitError}
                  </p>
                )}
                {fitReport && (
                  <div className="space-y-8 mt-2">
                    <p className="text-sm text-muted-foreground">
                      Latest test date: <span className="text-foreground font-medium">{fitReport.test_date}</span>
                    </p>

                    {/* 1. The Hero Cards */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                      {Object.entries(fitReport.division_alignment).map(([div, score]) => {
                        const isRecommended = div === fitReport.recommended_division;

                        return (
                          <div
                            key={div}
                            className={`relative flex flex-col items-center justify-center rounded-2xl border p-4 transition-all duration-300 ${
                              isRecommended
                                ? "border-emerald bg-emerald/10 shadow-lg scale-105 z-10"
                                : "border-border bg-card/40 opacity-50"
                            }`}
                          >
                            {isRecommended && (
                              <div className="absolute -top-3 bg-emerald text-primary-foreground text-[9px] font-bold uppercase tracking-widest px-3 py-1 rounded-full shadow-md">
                                ★ Best Fit
                              </div>
                            )}
                            <div className={`text-xs font-bold uppercase tracking-wide ${isRecommended ? "text-emerald" : "text-muted-foreground"}`}>
                              {div}
                            </div>
                            <div className={`mt-2 font-black tracking-tight ${isRecommended ? "text-4xl text-foreground" : "text-2xl text-muted-foreground"}`}>
                              {score}%
                            </div>
                          </div>
                        );
                      })}
                    </div>

                    {/* 2. The Strengths & Weaknesses Badges */}
                    <div className="grid grid-cols-1 gap-6 pt-4 border-t border-border/50">
                      {fitReport.strengths.length > 0 && (
                        <div>
                          <h4 className="text-xs font-bold uppercase tracking-wider text-emerald mb-3">Strengths</h4>
                          <div className="flex flex-wrap gap-2">
                            {fitReport.strengths.map((s, i) => {
                              const drillName = s.split(" is ")[0];
                              return (
                                <span key={i} className="px-3 py-1.5 bg-emerald/10 text-emerald-light border border-emerald/20 rounded-full text-xs font-semibold shadow-sm">
                                  {drillName}
                                </span>
                              );
                            })}
                          </div>
                        </div>
                      )}

                      {fitReport.weaknesses.length > 0 && (
                        <div>
                          <h4 className="text-xs font-bold uppercase tracking-wider text-destructive mb-3">Areas to develop</h4>
                          <div className="flex flex-wrap gap-2">
                            {fitReport.weaknesses.map((w, i) => {
                              const drillName = w.split(" is ")[0];
                              return (
                                <span key={i} className="px-3 py-1.5 bg-destructive/10 text-destructive border border-destructive/20 rounded-full text-xs font-semibold shadow-sm">
                                  {drillName}
                                </span>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                )}
                {!fitReport && !fitError && (
                  <p className="text-sm text-muted-foreground">Load a report after you have saved at least one test entry.</p>
                )}
              </CardContent>
            </Card>
          </div>

          {/* RIGHT SIDE: Master Data Entry (7 Columns) */}
          <div className="xl:col-span-7 flex flex-col">
            <Card className="border-border shadow-card h-full">
              <CardHeader className="border-b border-border/50 pb-4 mb-4">
                <CardTitle className="text-xl">Athlete Control Center</CardTitle>
                <CardDescription>Update your physical profile and log new session measurables.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-8">

                {/* Part 1: Physical Profile */}
                <form onSubmit={handleSaveProfile} className="space-y-4">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Physical Profile</h3>
                  <div className="grid grid-cols-3 gap-4">
                    <div className="space-y-1.5">
                      <Label htmlFor="grad-year" className="text-xs">Grad year</Label>
                      <Input id="grad-year" inputMode="numeric" value={gradYear} onChange={(e) => setGradYear(e.target.value)} placeholder="2027" className="bg-background h-8 text-sm" />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="height-in" className="text-xs">Height (in)</Label>
                      <Input id="height-in" inputMode="decimal" value={heightIn} onChange={(e) => setHeightIn(e.target.value)} placeholder="70" className="bg-background h-8 text-sm" />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="weight-lb" className="text-xs">Weight (lb)</Label>
                      <Input id="weight-lb" inputMode="decimal" value={weightLb} onChange={(e) => setWeightLb(e.target.value)} placeholder="165" className="bg-background h-8 text-sm" />
                    </div>
                  </div>
                  <Button type="submit" disabled={isSubmitting} variant="secondary" className="w-full h-8 text-xs">
                    {isSubmitting ? "Saving…" : "Save Physical Profile"}
                  </Button>
                </form>

                <div className="h-px bg-border/50 w-full" />

                {/* Part 2: Measurables */}
                <form onSubmit={handleLogTest} className="space-y-6">
                  <h3 className="text-xs font-bold uppercase tracking-wider text-muted-foreground">Log New Measurables</h3>
                  {TEST_FIELD_GROUPS.map((group) => (
                    <div key={group.title}>
                      <h4 className="text-[10px] font-bold uppercase tracking-wider text-emerald mb-2">{group.title}</h4>
                      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                        {group.keys.map((key) => (
                          <div key={key} className="space-y-1">
                            <Label htmlFor={`test-${key}`} className="text-[10px] text-muted-foreground font-normal leading-tight">
                              {testFieldLabelWithUnit(key)}
                            </Label>
                            <Input id={`test-${key}`} inputMode="decimal" value={testForm[key]} onChange={(e) => setTestForm((prev) => ({ ...prev, [key]: e.target.value }))} placeholder="—" className="bg-background h-8 text-sm" />
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                  <Button type="submit" disabled={savingTest} className="bg-emerald hover:bg-emerald-light text-primary-foreground w-full">
                    {savingTest ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Save Test Entry"}
                  </Button>
                </form>

              </CardContent>
            </Card>
          </div>

        </div>

        {/* ========================================= */}
        {/* ROW 3: THE LEDGER (History)               */}
        {/* ========================================= */}
        <div>
          <Card className="border-border shadow-card">
            <CardHeader>
              <CardTitle className="text-xl">Test history</CardTitle>
              <CardDescription>Entries are ordered with the newest first.</CardDescription>
            </CardHeader>
            <CardContent>
              {testsSorted.length === 0 ? (
                <p className="text-sm text-muted-foreground">No tests logged yet.</p>
              ) : (
                <div className="rounded-md border border-border overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="whitespace-nowrap">Date</TableHead>
                        <TableHead>Summary</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {testsSorted.map((t) => (
                        <TableRow key={t.id ?? `${t.test_date}-${summarizeTest(t)}`}>
                          <TableCell className="font-medium whitespace-nowrap">{t.test_date ?? "—"}</TableCell>
                          <TableCell className="text-muted-foreground text-sm max-w-xl">{summarizeTest(t)}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

      </main>
    </div>
  );
}
