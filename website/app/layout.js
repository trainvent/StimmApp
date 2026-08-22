import './globals.css';

const hostTitleScript = `
  (() => {
    const hostname = window.location.hostname.toLowerCase();
    const expectedTitle = hostname === 'vivot.net' || hostname.endsWith('.vivot.net')
      ? 'Vivot'
      : 'StimmApp';
    const updateTitle = () => {
      if (document.title !== expectedTitle) document.title = expectedTitle;
    };

    updateTitle();
    new MutationObserver(updateTitle).observe(document.head, {
      childList: true,
      subtree: true,
      characterData: true,
    });
  })();
`;

export const metadata = {
  title: 'StimmApp',
  description: 'StimmApp ist als Werkzeug für digitale Beteiligung gedacht.',
  icons: {
    icon: 'favicon.png',
    apple: 'apple-icon.png',
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="de">
      <body>
        {children}
        <script dangerouslySetInnerHTML={{ __html: hostTitleScript }} />
      </body>
    </html>
  );
}
