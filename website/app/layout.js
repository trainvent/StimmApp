import './globals.css';

export const metadata = {
  title: 'StimmApp',
  description: 'StimmApp ist als Werkzeug fuer digitale Beteiligung gedacht.',
};

export default function RootLayout({ children }) {
  return (
    <html lang="de">
      <body>{children}</body>
    </html>
  );
}
