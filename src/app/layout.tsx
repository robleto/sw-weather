import type { Metadata } from "next";
import { Exo_2, Poiret_One } from "next/font/google";
import "./globals.css";

const exo2 = Exo_2({ subsets: ["latin"], variable: "--font-exo2" });
const poiretOne = Poiret_One({ subsets: ["latin"], weight: "400", variable: "--font-poiret" });
const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
const siteName = "Otherworld Weather";
const description =
  "Find your weather's twin. Otherworld Weather matches today's local forecast to a world beyond our own.";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: siteName,
    template: `%s | ${siteName}`,
  },
  description,
  applicationName: siteName,
  keywords: [
    "weather",
    "forecast",
    "weather app",
    "location weather",
    "weather twin",
    "otherworld weather",
  ],
  openGraph: {
    title: siteName,
    description,
    type: "website",
    url: "/",
    siteName,
    // Social card image intentionally omitted until original artwork exists.
    // Re-add as: images: [{ url: "/og-card.png", width: 1200, height: 630, alt: siteName }]
    // and switch the twitter card below back to "summary_large_image".
  },
  twitter: {
    card: "summary",
    title: siteName,
    description,
  },
  alternates: {
    canonical: "/",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${exo2.variable} ${poiretOne.variable}`}>{children}</body>
    </html>
  );
}
