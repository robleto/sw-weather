import React from "react";
import styles from "../styles/page.module.css";

const Footer: React.FC = () => (
	<footer className={styles.footer}>
		<p className={styles.inspiredBy}>
			Inspired by the original, now defunct, Star Wars Weather
		</p>
		<div className={styles.credits}>
			Designed and developed by Greg Robleto
		</div>
	</footer>
);

export default Footer;
