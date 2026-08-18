import type { Metadata } from "next";
import Link from "next/link";
import styles from "../styles/privacy.module.css";

export const metadata: Metadata = {
	title: "Support",
	description:
		"Help with Galactic Weather — location permissions, restoring a purchase, and where your Atlas and Passport are actually stored.",
	alternates: { canonical: "/support" },
};

/**
 * The Support URL App Store Connect asks for at submission. That field is
 * separate from the privacy policy URL and both are required, which is the
 * reason this page exists at all.
 *
 * Written to be genuinely useful rather than to fill the field: every question
 * below is one this app's actual design produces. Device-local storage,
 * deferred location permission, iCloud-only sync and Apple-owned purchases are
 * all deliberate architectural choices, and each of them generates a
 * predictable "why did that happen?" — which is exactly what a support page
 * should answer.
 *
 * Deliberately free of specific numbers (how many saved locations, how many
 * worlds). Those move, and a support page that quietly goes stale is worse
 * than one that stays general.
 */
const LAST_UPDATED = "18 August 2026";

const SupportPage = () => (
	<main className={styles.page}>
		<article className={styles.content}>
			<p className={styles.eyebrow}>Galactic Weather</p>
			<h1 className={styles.heading}>Support</h1>
			<p className={styles.updated}>Last updated {LAST_UPDATED}</p>

			<p className={styles.lede}>
				Galactic Weather matches your local forecast to a world beyond our own.
				If something isn&apos;t working, the answer is probably below — and if
				it isn&apos;t, please get in touch.
			</p>

			<h2 className={styles.subheading}>Getting in touch</h2>
			<p>
				Email{" "}
				<a href="mailto:greg.robleto@creativemadness.studio">
					greg.robleto@creativemadness.studio
				</a>
				. This is a small independent app made by one person, so replies are
				not instant — but they are from the person who wrote it.
			</p>
			<p>
				When reporting a problem, it helps enormously to include which app you
				were using (iPhone or the website), what you were doing, and the name
				of the location you were looking at.
			</p>

			<h2 className={styles.subheading}>It won&apos;t use my location</h2>
			<p>
				The app only asks for location when you tap the location button — not
				at launch — so if you&apos;ve never been asked, that&apos;s why. Tap
				it and you&apos;ll get the system prompt.
			</p>
			<p>
				If you previously declined, iOS will not ask again, and no button in the
				app can make it. Go to{" "}
				<strong>Settings → Privacy &amp; Security → Location Services →
				Galactic Weather</strong>{" "}
				and choose <em>While Using the App</em>. On the website, the same
				permission is managed by your browser, usually from the icon at the left
				of the address bar.
			</p>
			<p>You can always search for any place by name instead.</p>

			<h2 className={styles.subheading}>The weather looks wrong</h2>
			<p>
				Forecasts come from{" "}
				<a href="https://openweathermap.org/" target="_blank" rel="noopener noreferrer">
					OpenWeather
				</a>{" "}
				and are shown as received. For a location without a nearby station, the
				reading may come from some distance away. The world shown alongside it is
				a creative interpretation of that forecast and means nothing
				meteorologically — please don&apos;t plan around it. For decisions that
				matter, use your national weather service.
			</p>

			<h2 className={styles.subheading}>My Atlas or Passport disappeared</h2>
			<p>
				Both live on your device rather than on a server — there are no accounts
				in this app and nothing of yours is stored anywhere we can reach. On the
				website that means your browser&apos;s local storage, so clearing site
				data, or opening the site in a private window or a different browser,
				starts you fresh. On iPhone, deleting the app removes them.
			</p>
			<p>
				This also means the website and the iPhone app keep{" "}
				<strong>separate</strong> collections. They don&apos;t sync to each
				other, and a stamp earned in one won&apos;t appear in the other.
			</p>
			<p>
				Because there&apos;s no copy on our side, a lost Passport can&apos;t be
				restored. That&apos;s the honest trade for an app that collects nothing
				about you.
			</p>

			<h2 className={styles.subheading}>A stamp didn&apos;t appear</h2>
			<p>
				A world is stamped once you&apos;ve stayed on it for a couple of
				seconds — swiping quickly past a location deliberately leaves no trace,
				so a fast flick through saved places doesn&apos;t fill your book with
				worlds you never looked at.
			</p>
			<p>
				Each world is also stamped once per day. Seeing the same world again the
				same day won&apos;t add another page, which is what keeps the count
				meaningful.
			</p>

			<h2 className={styles.subheading}>Saved locations aren&apos;t syncing</h2>
			<p>
				On iPhone, saved locations and your Atlas sync through your own iCloud
				account, so every device signed in to the same Apple Account shares
				them. If they aren&apos;t appearing on another device, check that both
				are signed in to the same account and have iCloud Drive turned on, then
				give it a moment — iCloud syncs on its own schedule.
			</p>

			<h2 className={styles.subheading}>Purchases and refunds</h2>
			<p>
				Galactic Weather Premium is a one-time purchase on iPhone — buy it once
				and it&apos;s yours, with no subscription. If you&apos;ve reinstalled or
				moved to a new device, use <strong>Restore Purchases</strong> on the
				Account screen; it asks Apple, so make sure you&apos;re signed in with
				the same Apple Account you bought it with.
			</p>
			<p>
				Refunds are handled entirely by Apple through{" "}
				<a
					href="https://reportaproblem.apple.com/"
					target="_blank"
					rel="noopener noreferrer"
				>
					reportaproblem.apple.com
				</a>
				. We never see your payment details and can&apos;t issue refunds
				ourselves.
			</p>
			<p>The website is free and has no premium tier at all.</p>

			<h2 className={styles.subheading}>Also worth reading</h2>
			<p>
				The <Link href="/privacy">privacy policy</Link> covers what the app
				collects, and the <Link href="/terms">terms</Link> cover what it
				promises. Both are short.
			</p>

			<p className={styles.back}>
				<Link href="/">← Back to the forecast</Link>
			</p>
		</article>
	</main>
);

export default SupportPage;
