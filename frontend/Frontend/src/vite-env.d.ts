/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** e.g. http://127.0.0.1:8000 — omit in dev to use the Vite proxy (same-origin). */
  readonly VITE_API_BASE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
