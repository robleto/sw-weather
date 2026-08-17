const STORAGE_KEY = "galacticweather:analytics:v1";

/** The slice of `Storage` this needs, so tests can pass a plain object. */
export interface IdStore {
	getItem(key: string): string | null;
	setItem(key: string, value: string): void;
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Recognizing the same browser twice is the whole of "did someone come back",
 * and it is the only thing here that needs justifying to a user.
 *
 * A random UUID in localStorage, tied to nothing. Note it shares a lifetime
 * with the Passport, which already lives in localStorage — someone who clears
 * site data loses their book, so this identifier is not a new category of
 * persistence, it expires exactly when the product's own memory does.
 *
 * Anything unrecognizable is replaced rather than trusted, so a hand-edited or
 * corrupted value can't become a long-lived junk identity in the dashboard.
 */
export const resolveClientId = (store: IdStore, generate: () => string): string => {
	const existing = store.getItem(STORAGE_KEY);
	if (typeof existing === "string" && UUID_PATTERN.test(existing)) return existing;

	const fresh = generate();
	store.setItem(STORAGE_KEY, fresh);
	return fresh;
};

/**
 * Browser entry point. Returns null when storage is unavailable (private mode,
 * quota, blocked cookies) — analytics then simply stays off for that visit
 * rather than inventing a new identity on every page load, which would report
 * one returning user as an unbounded stream of new ones.
 */
export const loadClientId = (): string | null => {
	if (typeof window === "undefined") return null;
	try {
		return resolveClientId(window.localStorage, () => crypto.randomUUID());
	} catch {
		return null;
	}
};

export const __testing = { STORAGE_KEY, UUID_PATTERN };
