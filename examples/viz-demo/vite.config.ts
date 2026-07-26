import { defineConfig } from "vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  root: ".",
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
