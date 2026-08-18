import type { Metadata } from "next";
import Link from "next/link";
import styles from "../styles/privacy.module.css";

export const metadata: Metadata = {
	title: "Terms",
	description:
		"The short version: Galactic Weather is for fun, the forecast comes from someone else, and it is not something to make real decisions on.",
	alternates: { canonical: "/terms" },
};

/**
 * Terms of use, sharing `privacy.module.css` deliberately — the two pages are
 * the same kind of document and should read as a pair.
 *
 * Not legally mandated. It exists for one paragraph in particular: this app
 * shows real forecasts, and sooner or later someone decides something based on
 * one. Saying plainly that it is entertainment, that the data is a third
 * party's, and that it can be wrong is the whole point.
 *
 * iOS is covered by Apple's standard EULA, which applies by default to any app
 * that doesn't supply its own, so this page is really about the web app.
 */
const LAST_UPDATED = "18 August 2026";

const TermsPage = () => (
	<main className={styles.page}>
		<article className={styles.content}>
			<p className={styles.eyebrow}>Galactic Weather</p>
			<h1 className={styles.heading}>Terms</h1>
			<p className={styles.updated}>Last updated {LAST_UPDATED}</p>

			<p className={styles.lede}>
				Galactic Weather is a weather app that matches your forecast to a
				fictional world. It is made for enjoyment, it is free on the web, and
				using it means accepting the few things below.
			</p>

			<h2 className={styles.subheading}>Don&apos;t rely on it</h2>
			<p>
				<strong>
					This is not a safety tool, and it should not be used as one.
				</strong>{" "}
				Do not use Galactic Weather to decide whether to fly, sail, drive,
				travel, work outdoors, or do anything else where being wrong about the
				weather carries a cost. For those decisions, use your national weather
				service or another authoritative source.
			</p>
			<p>
				The forecast is not ours. It comes from{" "}
				<a href="https://openweathermap.org/" target="_blank" rel="noopener noreferrer">
					OpenWeather
				</a>
				, is passed along as received, and may be inaccurate, delayed,
				incomplete, or unavailable. The world shown alongside it is a creative
				interpretation of that data and carries no meteorological meaning
				whatsoever.
			</p>
			<p>
				The app is provided as-is, without warranties of any kind. To the extent
				the law allows, we are not liable for any loss arising from using it or
				from being unable to use it.
			</p>

			<h2 className={styles.subheading}>Your collection lives on your device</h2>
			<p>
				Your Atlas assignments and your Passport are stored on your own device,
				not on a server. That means they can be lost — by clearing your
				browser&apos;s site data, by deleting the app, or by a device failing —
				and there is no backup anywhere for us to restore from. Please don&apos;t
				treat your Passport as permanent.
			</p>

			<h2 className={styles.subheading}>The artwork</h2>
			<p>
				Every world is an original digital design. The artwork is not public
				domain and is not licensed for reuse: please don&apos;t copy, resell, or
				redistribute it. Prints of the full set are available at{" "}
				<a
					href="https://creativemadness.studio"
					target="_blank"
					rel="noopener noreferrer"
				>
					creativemadness.studio
				</a>
				.
			</p>
			<p>
				World names are used affectionately, not officially. Galactic Weather is
				an independent project and is not affiliated with, endorsed by, or
				sponsored by any film studio, franchise, or rights holder.
			</p>

			<h2 className={styles.subheading}>Fair use of the app</h2>
			<p>
				The web app is free and there is nothing to sign up for. Please
				don&apos;t scrape it, hammer its endpoints, or use it as a backdoor to
				the weather API behind it — the quota is a real cost and an
				individual&apos;s.
			</p>

			<h2 className={styles.subheading}>Purchases</h2>
			<p>
				The iOS app offers a one-time premium purchase, handled entirely by
				Apple. Refunds are Apple&apos;s to give and are requested through them,
				not through us. Apple&apos;s{" "}
				<a
					href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
					target="_blank"
					rel="noopener noreferrer"
				>
					standard licence terms
				</a>{" "}
				also apply to the iOS app.
			</p>

			<h2 className={styles.subheading}>Changes</h2>
			<p>
				These terms may change as the app does. The date at the top moves when
				they do. See also the{" "}
				<Link href="/privacy">privacy policy</Link>, which covers what the app
				collects — the short version being: almost nothing.
			</p>

			<h2 className={styles.subheading}>Contact</h2>
			<p>
				Questions about any of this can go to{" "}
				<a href="mailto:greg.robleto@creativemadness.studio">
					greg.robleto@creativemadness.studio
				</a>
				.
			</p>

			<p className={styles.back}>
				<Link href="/">← Back to the forecast</Link>
			</p>
		</article>
	</main>
);

export default TermsPage;
