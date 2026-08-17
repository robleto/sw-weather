import { defineConfig } from "vitest/config";

export default defineConfig({
	resolve: {
		// Picks up the `@/*` alias from tsconfig.json so tests import modules the
		// same way the app does.
		tsconfigPaths: true,
	},
	test: {
		environment: "node",
		include: ["src/**/*.test.ts"],
	},
});
