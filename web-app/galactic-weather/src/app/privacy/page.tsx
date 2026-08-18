import type { Metadata } from "next";
import Link from "next/link";
import styles from "../styles/privacy.module.css";

export const metadata: Metadata = {
	title: "Privacy",
	description:
		"What Galactic Weather collects, what it doesn't, and where the little it does collect goes.",
	alternates: { canonical: "/privacy" },
};

/**
 * The canonical privacy policy for both the web app and the iOS app, and the
 * URL given to App Store Connect at submission.
 *
 * Deliberately the only copy. A second one in the repo or in the App Store
 * listing would drift, and a privacy policy that no longer describes the code
 * is worse than none — it's a false statement rather than a missing one.
 *
 * Keep it true by construction: the analytics section below describes exactly
 * the six signals in `shared/analytics-signals.json`, and the payload
 * allowlist there is enforced by tests on both platforms.
 */
const LAST_UPDATED = "17 August 2026";

const PrivacyPage = () => (
	<main className={styles.page}>
		<article className={styles.content}>
			<p className={styles.eyebrow}>Galactic Weather</p>
			<h1 className={styles.heading}>Privacy</h1>
			<p className={styles.updated}>Last updated {LAST_UPDATED}</p>

			<p className={styles.lede}>
				Galactic Weather has no accounts, no login, and no user database. It
				never asks for your name or your email, and there is nowhere for it to
				store them if it did. This page describes the data that does move, and
				where it goes.
			</p>

			<h2 className={styles.subheading}>Your location</h2>
			<p>
				To show a forecast, the app needs somewhere to get one for. That is
				either the location your device reports, if you allow it, or a place you
				type in.
			</p>
			<p>
				Those coordinates are used to fetch weather from{" "}
				<a href="https://openweathermap.org/" target="_blank" rel="noopener noreferrer">
					OpenWeatherMap
				</a>{" "}
				and then discarded. They are not stored on any server, not logged, and
				not attached to any identifier.
			</p>
			<p>
				One difference between the two apps is worth stating plainly. On the
				web, the request to OpenWeatherMap is made by this site&apos;s own
				server, so OpenWeatherMap sees the coordinates but not your browser or
				IP address. On iOS, the app calls OpenWeatherMap directly from your
				device, so their servers see your device&apos;s IP address the way any
				website you visit would. Their handling of that is covered by their own
				privacy policy.
			</p>
			<p>
				If you save locations on iOS, those are stored in your own iCloud
				account so they follow you between your devices. They go to Apple, not
				to us, and we cannot read them.
			</p>

			<h2 className={styles.subheading}>What stays on your device</h2>
			<p>
				Your Atlas assignments and your Passport — the worlds you&apos;ve landed
				on — live on your device. On the web that means your browser&apos;s local
				storage; on iOS it means your device and your iCloud account. Clearing
				your browser&apos;s site data, or deleting the app, deletes them. There is
				no copy anywhere else, which also means we cannot restore them for you.
			</p>

			<h2 className={styles.subheading}>Analytics</h2>
			<p>
				The app records a small number of anonymous usage signals through{" "}
				<a href="https://telemetrydeck.com/" target="_blank" rel="noopener noreferrer">
					TelemetryDeck
				</a>
				, a privacy-focused analytics service. This exists to answer one
				question: whether anyone finds this thing worth coming back to.
			</p>
			<p>These are all of them, and they carry nothing else:</p>
			<ul className={styles.list}>
				<li>
					<strong>App launched</strong> — that the app was opened.
				</li>
				<li>
					<strong>Forecast landed</strong> — that a forecast loaded, and which
					weather category it fell into (&ldquo;snow&rdquo;, &ldquo;clear and
					scorching&rdquo;).
				</li>
				<li>
					<strong>Atlas opened</strong> — that the Atlas screen was viewed.
				</li>
				<li>
					<strong>World assigned</strong> — that a weather category was
					reassigned, and which category.
				</li>
				<li>
					<strong>Stamp earned</strong> — that a Passport stamp was awarded,
					which weather category earned it, and roughly how many stamps you have
					(as a range such as &ldquo;6&ndash;15&rdquo;, never an exact number).
				</li>
				<li>
					<strong>Paywall shown</strong> (iOS only) — that the premium screen
					was displayed, and which feature led there.
				</li>
			</ul>
			<p>
				Deliberately absent from every one of those: the place you searched for,
				your coordinates, the temperature, and the name of the world you landed
				on. The weather category is sent instead of the world, because it
				answers the same question and describes weather rather than you.
			</p>
			<p>
				To tell a returning visitor from a new one, each install carries a
				random identifier. On the web that is a random number stored in your
				browser alongside your Passport, so clearing your site data clears it
				too. On iOS it is derived from an Apple-provided per-vendor identifier
				and hashed before it is sent. Neither is linked to you, and neither is
				used to track you across other apps or websites.
			</p>
			<p>
				On the web, analytics is switched off entirely if your browser sends{" "}
				<em>Do Not Track</em> or <em>Global Privacy Control</em>. You do not
				have to ask us; the app checks before it sends anything.
			</p>

			<h2 className={styles.subheading}>Purchases</h2>
			<p>
				The iOS app offers a one-time premium purchase. That transaction is
				handled entirely by Apple. We never see your payment details, and there
				is no server on our side that records who has bought anything — the app
				asks your device whether the purchase exists. Restoring a purchase asks
				Apple, not us.
			</p>

			<h2 className={styles.subheading}>What is never collected</h2>
			<ul className={styles.list}>
				<li>Names, email addresses, or contact details.</li>
				<li>Advertising identifiers. There is no advertising, and no tracking across apps or sites.</li>
				<li>Your search history or the places you look up.</li>
				<li>Anything at all that is sold or shared with data brokers.</li>
			</ul>
			{/*
			  Stated explicitly, in close to the statutory words, rather than left to
			  be inferred from the list above. California's rule is that a business
			  which genuinely doesn't sell or share personal information isn't
			  required to post a "Do Not Sell or Share" link — but it does have to
			  say so plainly. "Share" there is a term of art meaning
			  cross-context behavioral advertising, which is why the ad sentence sits
			  next to it. If this app ever gains an ad SDK or a retargeting pixel,
			  this paragraph stops being true and a link becomes required.
			*/}
			<p>
				<strong>
					We do not sell your personal information, and we do not share it for
					cross-context behavioral advertising.
				</strong>{" "}
				There is no advertising in Galactic Weather, no ad network, and no
				tracking of you across other apps or websites — so there is nothing to
				opt out of. Browsers that send a Global Privacy Control signal are
				honored anyway, and switch analytics off entirely.
			</p>

			<h2 className={styles.subheading}>Children</h2>
			<p>
				Galactic Weather is a weather app suitable for all ages and collects no
				personal information from anyone, including children.
			</p>

			<h2 className={styles.subheading}>Changes</h2>
			<p>
				If what the app collects changes, this page changes with it, and the
				date at the top moves. It is written from the code rather than from
				intentions, and the list of signals above is checked by the app&apos;s own
				test suite.
			</p>

			<h2 className={styles.subheading}>Contact</h2>
			<p>
				Questions about any of this, including any request concerning your own
				data, can go to{" "}
				<a href="mailto:greg.robleto@creativemadness.studio">
					greg.robleto@creativemadness.studio
				</a>
				.
			</p>

			<p className={styles.back}>
				<Link href="/">← Back to the forecast</Link> · <Link href="/terms">Terms</Link>
			</p>
		</article>
	</main>
);

export default PrivacyPage;
