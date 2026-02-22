'use client';

import 'bootstrap/dist/css/bootstrap.min.css';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <title>InkaWallet Admin Panel</title>
      </head>
      <body>{children}</body>
    </html>
  );
}
