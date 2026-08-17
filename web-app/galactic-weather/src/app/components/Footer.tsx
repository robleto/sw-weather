import React from "react";
import styles from "../styles/Footer.module.css";

/**
 * One line: the artwork.
 *
 * The attribution bylines and the Privacy link used to sit here on a dim second
 * line; they moved into the nav's "…" menu, mirroring what the iOS dropdown
 * became — housekeeping out of sight, the things people came for in reach. What
 * stays is a product statement rather than housekeeping: the worlds are original
 * paintings and the prints are for sale, which is worth a line under the
 * forecast.
 *
 * Deliberately text only. Poster thumbnails belong on iOS's Credits screen — a
 * place you navigate to — but in a 13px bar pinned under the forecast they'd
 * read as an ad strip, which is the one thing this must not become.
 */
const Footer: React.FC = () => (
	<footer className={styles.footer}>
		<p className={styles.artworkCredit}>
			Every world here is an original painting — a travel poster for somewhere
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
	</footer>
);

export default Footer;
