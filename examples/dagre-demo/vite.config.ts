import { URL, fileURLToPath } from "node:url";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  root: ".",
  plugins: [tailwindcss()],
  server: {
    port: 5173,
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
      dagre: fileURLToPath(new URL("node_modules/dagre", import.meta.url)),
    },
  },
  optimizeDeps: {
    include: ["dagre"],
  },
});
