'use client';

import { useEffect, useState } from 'react';

const formRoutePattern = /^\/(petition|poll|survey)\/[^/]+\/?$/;

export default function NotFoundPage() {
  const [isRedirecting, setIsRedirecting] = useState(true);

  useEffect(() => {
    const { hostname, pathname, search, hash } = window.location;
    if (!formRoutePattern.test(pathname)) {
      setIsRedirecting(false);
      return;
    }

    const appOrigin = hostname.toLowerCase().includes('vivot.net')
      ? 'https://web.vivot.net'
      : 'https://web.stimmapp.net';
    window.location.replace(`${appOrigin}${pathname}${search}${hash}`);
  }, []);

  return (
    <main className="invite-page">
      <section className="section-card invite-card">
        <img
          className="invite-logo"
          src="/icons/Icon-512.png"
          alt="StimmApp"
        />
        <h1>{isRedirecting ? 'Formular wird geöffnet…' : 'Seite nicht gefunden'}</h1>
        <p>
          {isRedirecting
            ? 'Du wirst zur StimmApp-Web-App weitergeleitet.'
            : 'Die angeforderte Seite existiert nicht.'}
        </p>
        {!isRedirecting && (
          <a className="button" href="/">
            Zur Startseite
          </a>
        )}
      </section>
    </main>
  );
}
