import type { Metadata } from "next";

import "../../../../../styles/globals.css";

export const metadata: Metadata = {
  title: "JS Empire",
  description: "JS Empire",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html>
      <body>{children}</body>
    </html>
  );
}
