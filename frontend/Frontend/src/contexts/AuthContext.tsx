import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  fetchAthleteProfile,
  loginUser,
  logoutUser,
  registerUser,
  updateAthleteProfile,
  type AthleteProfile,
} from "@/lib/api";

type AuthContextValue = {
  user: AthleteProfile | null;
  isBootstrapping: boolean;
  isSubmitting: boolean;
  refreshSession: () => Promise<void>;
  login: (username: string, password: string) => Promise<void>;
  register: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (data: Partial<Pick<AthleteProfile, "grad_year" | "height_in" | "weight_lb">>) => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AthleteProfile | null>(null);
  const [isBootstrapping, setIsBootstrapping] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const refreshSession = useCallback(async () => {
    try {
      const profile = await fetchAthleteProfile();
      setUser(profile);
    } catch {
      setUser(null);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setIsBootstrapping(true);
      try {
        const profile = await fetchAthleteProfile();
        if (!cancelled) setUser(profile);
      } catch {
        if (!cancelled) setUser(null);
      } finally {
        if (!cancelled) setIsBootstrapping(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const login = useCallback(async (username: string, password: string) => {
    setIsSubmitting(true);
    try {
      await loginUser(username, password);
      const profile = await fetchAthleteProfile();
      setUser(profile);
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  const register = useCallback(async (username: string, password: string) => {
    setIsSubmitting(true);
    try {
      await registerUser(username, password);
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  const logout = useCallback(async () => {
    setIsSubmitting(true);
    try {
      await logoutUser();
      setUser(null);
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  const updateProfile = useCallback(
    async (data: Partial<Pick<AthleteProfile, "grad_year" | "height_in" | "weight_lb">>) => {
      setIsSubmitting(true);
      try {
        const next = await updateAthleteProfile(data);
        setUser(next);
      } finally {
        setIsSubmitting(false);
      }
    },
    [],
  );

  const value = useMemo(
    () => ({
      user,
      isBootstrapping,
      isSubmitting,
      refreshSession,
      login,
      register,
      logout,
      updateProfile,
    }),
    [user, isBootstrapping, isSubmitting, refreshSession, login, register, logout, updateProfile],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
