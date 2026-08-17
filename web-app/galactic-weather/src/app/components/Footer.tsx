import React from "react";
import Link from "next/link";
import styles from "../styles/Footer.module.css";

/**
 * The footer used to lead with attribution and carry a row of five social
 * icons (robleto.com, CodePen, Dribbble, GitHub, LinkedIn). That row is gone
 * and the hierarchy is inverted: the artwork gets the bright first line, the
 * bylines drop to a dim second one. robleto.com is still linked from the
 * byline, so nothing became unreachable.
 *
 * Deliberately text only. Poster thumbnails belong on iOS's Credits screen —
 * a place you navigate to — but in a 13px bar pinned under the forecast they'd
 * read as an ad strip, which is the one thing this must not become.
 */
const Footer: React.FC = () => (
	<footer className={styles.footer}>
		<p className={styles.artworkCredit}>
			Every world here is an original digital design — a travel poster for somewhere
			that doesn&apos;t exist. Prints of the full set are at{" "}
			<a
				href="https://creativemadness.studio"
				target="_blank"
				rel="noopener noreferrer"
			>
				creativemadness.studio
			</a>
			.
		</p>

		<p className={styles.meta}>
			Inspired by a{" "}
			<a
				href="https://www.tomscott.com/weather/starwars/"
				target="_blank"
				rel="noopener noreferrer"
			>
				weather site
			</a>{" "}
			from long ago. Designed and developed by{" "}
			<a
				href="https://www.robleto.com/"
				target="_blank"
				rel="noopener noreferrer"
			>
				Greg Robleto
			</a>
			. <Link href="/privacy">Privacy</Link>.
		</p>
	</footer>
);

export default Footer;
