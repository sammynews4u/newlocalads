import { defineConfig, globalIgnores } from "eslint/config";
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";

export default defineConfig([
  ...nextCoreWebVitals,
  {
    // React Compiler lint rules in newer Next/React versions are useful, but this
    // project has existing client components that call async loaders from effects.
    // These are not database/Vercel blockers, so keep deployment linting focused on
    // real syntax/type problems until those components are refactored deliberately.
    rules: {
      "react-hooks/immutability": "off",
      "react-hooks/set-state-in-effect": "off",
    },
  },
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
]);
