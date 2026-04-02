import Script from 'next/script';

import './globals.css';

export const metadata = {
  title: 'StimmApp',
  description: 'StimmApp ist als Werkzeug fuer digitale Beteiligung gedacht.',
  icons: {
    icon: '/favicon.png',
    apple: '/apple-icon.png',
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="de">
      <head>
        <Script
          id="adsense-site-code"
          async
          strategy="beforeInteractive"
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-6799570171188466"
          crossOrigin="anonymous"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
