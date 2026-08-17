"use client";
import React, { useEffect, useRef, useState } from "react";
import Link from "next/link";
import styles from "../styles/NavMenu.module.css";

/**
 * The small stuff, behind a "…" in the nav.
 *
 * This mirrors what iOS's dropdown became: Atlas and Passport are the things
 * people come here for and get real buttons, while attribution and legal — the
 * housekeeping — moves out of sight until asked for. The artwork credit stays in
 * the footer rather than moving in here; it's a product statement, not
 * housekeeping.
 *
 * iOS additionally has Settings and Account in its menu. Neither exists on web,
 * so this is deliberately shorter rather than padded out to match.
 */
const NavMenu: React.FC = () => {
	const [isOpen, setIsOpen] = useState(false);
	const containerRef = useRef<HTMLDivElement>(null);

	// A dropdown that only closes via its own button is a trap on a page where
	// everything else is clickable.
	useEffect(() => {
		if (!isOpen) return;

		const onPointerDown = (event: MouseEvent | TouchEvent) => {
			if (!containerRef.current?.contains(event.target as Node)) {
				setIsOpen(false);
			}
		};
		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === "Escape") setIsOpen(false);
		};

		document.addEventListener("mousedown", onPointerDown);
		document.addEventListener("touchstart", onPointerDown);
		document.addEventListener("keydown", onKeyDown);
		return () => {
			document.removeEventListener("mousedown", onPointerDown);
			document.removeEventListener("touchstart", onPointerDown);
			document.removeEventListener("keydown", onKeyDown);
		};
	}, [isOpen]);

	return (
		<div className={styles.container} ref={containerRef}>
			<button
				type="button"
				className={styles.trigger}
				onClick={() => setIsOpen((open) => !open)}
				aria-haspopup="menu"
				aria-expanded={isOpen}
				aria-label="More"
			>
				{/* Three dots as text: an icon font or SVG for one glyph isn't worth
				    the weight, and this scales with the button's font size. */}
				<span aria-hidden="true">···</span>
			</button>

			{isOpen && (
				<div className={styles.menu} role="menu">
					<p className={styles.credit}>
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
						.
					</p>

					<Link
						href="/privacy"
						className={styles.item}
						role="menuitem"
						onClick={() => setIsOpen(false)}
					>
						Privacy
					</Link>
				</div>
			)}
		</div>
	);
};

export default NavMenu;
