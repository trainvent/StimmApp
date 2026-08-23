import './globals.css';

export const metadata = {
  title: 'StimmApp',
  description: 'StimmApp ist als Werkzeug für digitale Beteiligung gedacht.',
  icons: {
    icon: '/favicon.png',
    apple: '/apple-icon.png',
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="de">
      <body>{children}</body>
    </html>
  );
}
