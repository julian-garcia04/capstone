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

      <main className="container mx-auto px-6 pb-20 space-y-10 -mt-4">
        <Card className="border-border shadow-card">
          <CardHeader>
            <CardTitle className="text-xl">Athlete details</CardTitle>
            <CardDescription>Grad year and body metrics used with your benchmark reports.</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSaveProfile} className="grid grid-cols-1 sm:grid-cols-3 gap-4 max-w-3xl">
              <div className="space-y-2">
                <Label htmlFor="grad-year">Grad year</Label>
                <Input
                  id="grad-year"
                  inputMode="numeric"
                  value={gradYear}
                  onChange={(e) => setGradYear(e.target.value)}
                  placeholder="2027"
                  className="bg-background"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="height-in">Height (in)</Label>
                <Input
                  id="height-in"
                  inputMode="decimal"
                  value={heightIn}
                  onChange={(e) => setHeightIn(e.target.value)}
                  placeholder="70"
                  className="bg-background"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="weight-lb">Weight (lb)</Label>
                <Input
                  id="weight-lb"
                  inputMode="decimal"
                  value={weightLb}
                  onChange={(e) => setWeightLb(e.target.value)}
                  placeholder="165"
                  className="bg-background"
                />
              </div>
              <div className="sm:col-span-3">
                <Button
                  type="submit"
                  disabled={isSubmitting}
                  className="bg-emerald hover:bg-emerald-light text-primary-foreground"
                >
                  {isSubmitting ? "Saving…" : "Save profile"}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        <Card className="border-border shadow-card">
          <CardHeader>
            <CardTitle className="text-xl">Log measurables</CardTitle>
            <CardDescription>
              Enter any metrics you have from a session. Leave fields blank if you did not run that test. At least one
              value is required to save a new entry. Each field shows the unit the API benchmarks expect (e.g. 40-yard
              dash in seconds, vertical jump in inches).
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleLogTest} className="space-y-8">
              {TEST_FIELD_GROUPS.map((group) => (
                <div key={group.title}>
                  <h3 className="text-sm font-bold uppercase tracking-wider text-emerald mb-3">{group.title}</h3>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                    {group.keys.map((key) => (
                      <div key={key} className="space-y-1.5">
                        <Label htmlFor={`test-${key}`} className="text-xs text-muted-foreground font-normal leading-snug">
                          {testFieldLabelWithUnit(key)}
                        </Label>
                        <Input
                          id={`test-${key}`}
                          inputMode="decimal"
                          value={testForm[key]}
                          onChange={(e) => setTestForm((prev) => ({ ...prev, [key]: e.target.value }))}
                          placeholder="—"
                          className="bg-background"
                        />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
              <Button
                type="submit"
                disabled={savingTest}
                className="bg-emerald hover:bg-emerald-light text-primary-foreground"
              >
                {savingTest ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Saving…
                  </>
                ) : (
                  "Save test entry"
                )}
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card className="border-border shadow-card overflow-hidden">
                  <CardHeader className="bg-gray-50/50 border-b border-gray-100">
                    <CardTitle className="text-xl">Visual Performance Radar</CardTitle>
                    <CardDescription>Compare your specific metrics against division standards.</CardDescription>
                      </CardHeader>
                  <iframe
            key={shinyUrl}
            src={shinyUrl}
            style={{ width: '100%', height: '700px', border: 'none' }}
            title="Starting XI Visual Fit Report"
          />
                </Card>
                {/* -------------------------------- */}
        <Card className="border-border shadow-card">
          <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <CardTitle className="text-xl flex items-center gap-2">
                <Sparkles className="h-5 w-5 text-gold" />
                Division fit
              </CardTitle>
              <CardDescription>
                Uses your most recent test row and NCAA division benchmarks from the API.
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
          <CardContent className="space-y-4">
            {fitError && (
              <p className="text-sm text-destructive bg-destructive/10 border border-destructive/20 rounded-md px-3 py-2">
                {fitError}
              </p>
            )}
            {fitReport && (
              <div className="space-y-4">
                <p className="text-sm text-muted-foreground">
                  Latest test date: <span className="text-foreground font-medium">{fitReport.test_date}</span>
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {Object.entries(fitReport.division_alignment).map(([div, score]) => (
                    <div
                      key={div}
                      className="rounded-xl border border-border bg-card px-4 py-3 text-center"
                    >
                      <div className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">{div}</div>
                      <div className="text-2xl font-bold text-foreground mt-1">{score}%</div>
                    </div>
                  ))}
                </div>
                <p className="text-sm">
                  <span className="text-muted-foreground">Recommended: </span>
                  <span className="font-semibold text-emerald">{fitReport.recommended_division}</span>
                </p>
                {fitReport.strengths.length > 0 && (
                  <div>
                    <h4 className="text-sm font-semibold text-foreground mb-2">Strengths</h4>
                    <ul className="list-disc list-inside text-sm text-muted-foreground space-y-1">
                      {fitReport.strengths.map((s, i) => (
                        <li key={i}>{s}</li>
                      ))}
                    </ul>
                  </div>
                )}
                {fitReport.weaknesses.length > 0 && (
                  <div>
                    <h4 className="text-sm font-semibold text-foreground mb-2">Areas to develop</h4>
                    <ul className="list-disc list-inside text-sm text-muted-foreground space-y-1">
                      {fitReport.weaknesses.map((w, i) => (
                        <li key={i}>{w}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            )}
            {!fitReport && !fitError && (
              <p className="text-sm text-muted-foreground">Load a report after you have saved at least one test entry.</p>
            )}
          </CardContent>
        </Card>

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
      </main>
    </div>
  );
}
