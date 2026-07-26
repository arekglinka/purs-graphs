import { URL, fileURLToPath } from "node:url";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  root: ".",
  plugins: [tailwindcss()],
  server: {
    port: 5174,
    open: true,
    fs: {
      allow: ["..", "../.."],
    },
  },
  build: {
    outDir: "dist",
    target: "esnext",
  },
  resolve: {
    alias: {
      "@viz-js/viz": fileURLToPath(new URL("node_modules/@viz-js/viz", import.meta.url)),
    },
  },
  optimizeDeps: {
    include: ["@viz-js/viz"],
  },
});
