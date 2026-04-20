/**
 * Session + CSRF helpers for the Django REST API.
 * Default: same-origin requests (Vite dev proxy to :8000). Set VITE_API_BASE_URL to call Django directly.
 */

import type { TestFieldKey } from "@/constants/athleteTests";

const API_BASE = "http://127.0.0.1:8000";

function getCookie(name: string): string | null {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop()?.split(";").shift() ?? null;
  return null;
}

/** Ensures Django sets the csrftoken cookie (required before POST/PUT/PATCH/DELETE). */
export async function ensureCsrf(): Promise<void> {
  if (getCookie("csrftoken")) return;
  const res = await fetch(`${API_BASE}/api/benchmarks/`, { credentials: "include" });
  if (!res.ok) throw new Error("Could not initialize session (CSRF). Is the API running?");
  if (!getCookie("csrftoken")) {
    throw new Error("CSRF cookie was not set. Check Django CSRF_TRUSTED_ORIGINS for this origin.");
  }
}

export async function apiFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const method = (init.method ?? "GET").toUpperCase();
  const needsCsrf = ["POST", "PUT", "PATCH", "DELETE"].includes(method);
  if (needsCsrf) await ensureCsrf();
  const headers = new Headers(init.headers);
  if (needsCsrf) {
    const token = getCookie("csrftoken");
    if (token) headers.set("X-CSRFToken", token);
  }
  if (init.body != null && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  return fetch(`${API_BASE}${path}`, { ...init, credentials: "include", headers });
}

export async function parseApiError(res: Response): Promise<string> {
  try {
    const data = (await res.json()) as Record<string, unknown>;
    if (typeof data.detail === "string") return data.detail;
    if (Array.isArray(data.non_field_errors) && typeof data.non_field_errors[0] === "string") {
      return data.non_field_errors[0];
    }
    const firstKey = Object.keys(data)[0];
    const val = firstKey ? data[firstKey] : undefined;
    if (Array.isArray(val) && typeof val[0] === "string") return `${firstKey}: ${val[0]}`;
    if (typeof val === "string") return `${firstKey}: ${val}`;
  } catch {
    /* ignore */
  }
  return res.statusText || `Request failed (${res.status})`;
}

export type AthleteTest = Record<string, string | number | null | undefined> & {
  id?: number;
  test_date?: string;
};

export type AthleteProfile = {
  id: number;
  username: string;
  grad_year: number | null;
  height_in: number | null;
  weight_lb: number | null;
  tests: AthleteTest[];
};

export async function registerUser(username: string, password: string): Promise<void> {
  const res = await apiFetch("/api/register/", {
    method: "POST",
    body: JSON.stringify({ username, password }),
  });
  if (!res.ok) throw new Error(await parseApiError(res));
}

export async function loginUser(username: string, password: string): Promise<void> {
  const res = await apiFetch("/api/login/", {
    method: "POST",
    body: JSON.stringify({ username, password }),
  });
  if (!res.ok) throw new Error(await parseApiError(res));
}

export async function logoutUser(): Promise<void> {
  const res = await apiFetch("/api-auth/logout/", { method: "POST" });
  if (!res.ok) throw new Error(await parseApiError(res));
}

export async function fetchAthleteProfile(): Promise<AthleteProfile | null> {
  const res = await apiFetch("/api/athlete/me/");
  if (res.status === 401 || res.status === 403) return null;
  if (!res.ok) throw new Error(await parseApiError(res));
  return res.json() as Promise<AthleteProfile>;
}

export async function updateAthleteProfile(
  data: Partial<Pick<AthleteProfile, "grad_year" | "height_in" | "weight_lb">>,
): Promise<AthleteProfile> {
  const res = await apiFetch("/api/athlete/me/", {
    method: "PUT",
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(await parseApiError(res));
  return res.json() as Promise<AthleteProfile>;
}

/** POST a new AthleteTest row (any subset of metrics). */
export async function submitAthleteTest(metrics: Partial<Record<TestFieldKey, number>>): Promise<void> {
  const body: Record<string, number> = {};
  for (const [k, v] of Object.entries(metrics)) {
    if (typeof v === "number" && !Number.isNaN(v)) body[k] = v;
  }
  if (Object.keys(body).length === 0) {
    throw new Error("Enter at least one measurable.");
  }
  const res = await apiFetch("/api/athlete/tests/", {
    method: "POST",
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(await parseApiError(res));
}

export type FitReport = {
  username: string;
  test_date: string;
  division_alignment: Record<string, number>;
  recommended_division: string;
  strengths: string[];
  weaknesses: string[];
};

export async function fetchFitReport(): Promise<FitReport> {
  const res = await apiFetch("/api/athlete/fit/");
  if (!res.ok) throw new Error(await parseApiError(res));
  return res.json() as Promise<FitReport>;
}
