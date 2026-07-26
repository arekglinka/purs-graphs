import { defineConfig } from "vite";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  root: ".",
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
