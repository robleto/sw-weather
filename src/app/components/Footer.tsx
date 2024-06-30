import React from "react";
import styles from "../styles/Footer.module.css";

const socialMediaIcons = [
	{
		alt: "Website",
		src: "/images/_icons/website-icon.svg",
		href: "https://www.robleto.com",
	},
	{
		alt: "CodePen",
		src: "/images/_icons/codepen-icon.svg",
		href: "https://www.codepen.com/robleto",
	},
	{
		alt: "Dribbble",
		src: "/images/_icons/dribbble-icon.svg",
		href: "https://www.dribbble.com/robleto",
	},
	{
		alt: "GitHub",
		src: "/images/_icons/github-icon.svg",
		href: "https://www.github.com/robleto",
	},
	{
		alt: "LinkedIn",
		src: "/images/_icons/linkedin-icon.svg",
		href: "https://www.linkedin.com/in/robleto",
	},
];

const Footer: React.FC = () => (
	<footer className={styles.footer}>
		<div className={styles.footerText}>
			<p className={styles.inspiredText}>
				Inspired by another{" "}
				<a
					href="https://www.tomscott.com/weather/starwars/"
					target="_blank"
					rel="noopener noreferrer"
				>
					SW Weather
				</a> from long ago.
			</p>
			<p className={styles.developedBy}>
				Designed and developed by&nbsp;  {" "}
				<a
					href="https://www.robleto.com/"
					target="_blank"
					rel="noopener noreferrer"
				>
					 Greg Robleto
				</a>
			</p>
			<div className={styles.iconContainer}>
				{socialMediaIcons.map((icon) => (
					<a
						key={icon.alt}
						href={icon.href}
						target="_blank"
						rel="noopener noreferrer"
					>
						<img
							src={icon.src}
							alt={icon.alt}
							className={styles.socialIcon}
						/>
					</a>
				))}
			</div>
		</div>
	</footer>
);

export default Footer;
