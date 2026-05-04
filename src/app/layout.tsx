import type { Metadata } from "next";
import { Exo_2, Poiret_One } from "next/font/google";
import "./globals.css";

const exo2 = Exo_2({ subsets: ["latin"], variable: "--font-exo2" });
const poiretOne = Poiret_One({ subsets: ["latin"], weight: "400", variable: "--font-poiret" });
const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
const siteName = "Star Wars Weather";
const description =
  "Experience accurate weather forecasts with a Star Wars twist. Discover which planet your local weather feels like today.";

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
    "star wars",
    "forecast",
    "weather app",
    "location weather",
  ],
  openGraph: {
    title: siteName,
    description,
    type: "website",
    url: "/",
    siteName,
    images: [{ url: "/SWweather.png", width: 1200, height: 627, alt: siteName }],
  },
  twitter: {
    card: "summary_large_image",
    title: siteName,
    description,
    images: ["/SWweather.png"],
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
