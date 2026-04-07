import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    host: "::",
    port: 8080,
    hmr: {
      overlay: false,
    },
    // Proxy API to Django so the browser stays same-origin (session cookies + CSRF work).
    proxy: {
      "/api": { target: "http://127.0.0.1:8000", changeOrigin: true },
      "/api-auth": { target: "http://127.0.0.1:8000", changeOrigin: true },
    },
  },
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
