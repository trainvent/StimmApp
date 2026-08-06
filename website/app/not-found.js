'use client';

import { useEffect, useState } from 'react';

const formRoutePattern = /^\/(petition|poll|survey)\/[^/]+\/?$/;
const mobilePattern = /Android|iPhone|iPad|iPod|Mobile/i;

const copy = {
  de: {
    preparing: 'Link wird vorbereitet…',
    title: 'Wie möchtest du das Formular öffnen?',
    description: 'Öffne es in der App oder fahre direkt im Browser fort.',
    openApp: 'In der App öffnen',
    getApp: 'App herunterladen',
    continueWeb: 'Im Browser fortfahren',
    notFound: 'Seite nicht gefunden',
    notFoundDescription: 'Die angeforderte Seite existiert nicht.',
    home: 'Zur Startseite',
  },
  en: {
    preparing: 'Preparing link…',
    title: 'How would you like to open this form?',
    description: 'Open it in the app or continue directly in your browser.',
    openApp: 'Open in app',
    getApp: 'Get the app',
    continueWeb: 'Continue in browser',
    notFound: 'Page not found',
    notFoundDescription: 'The requested page does not exist.',
    home: 'Back to home',
  },
};

export default function NotFoundPage() {
  const [linkState, setLinkState] = useState({ status: 'preparing' });

  useEffect(() => {
    const { hostname, pathname, search, hash } = window.location;
    const isVivot = hostname.toLowerCase().includes('vivot.net');
    if (!formRoutePattern.test(pathname)) {
      setLinkState({ status: 'not-found', isVivot });
      return;
    }

    const appOrigin = isVivot
      ? 'https://web.vivot.net'
      : 'https://web.stimmapp.net';
    const webUrl = `${appOrigin}${pathname}${search}${hash}`;
    const appScheme = isVivot ? 'vivot' : 'stimmapp';
    const appUrl = `${appScheme}://${pathname.slice(1)}${search}${hash}`;
    const isMobile = mobilePattern.test(navigator.userAgent)
      || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

    if (!isMobile) {
      window.location.replace(webUrl);
      return;
    }

    const isAppleDevice = /iPhone|iPad|iPod/i.test(navigator.userAgent)
      || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
    setLinkState({
      status: 'choose',
      isVivot,
      appUrl,
      webUrl,
      storeUrl: isAppleDevice
        ? 'https://apps.apple.com/app/stimmapp/id6759249651'
        : 'https://play.google.com/store/apps/details?id=de.lemarq.stimmapp',
    });
  }, []);

  const isVivot = linkState.isVivot ?? false;
  const labels = isVivot ? copy.en : copy.de;
  const brand = isVivot ? 'Vivot' : 'StimmApp';
  const isChooser = linkState.status === 'choose';
  const isNotFound = linkState.status === 'not-found';

  return (
    <main className="invite-page">
      <section className="section-card invite-card form-link-card">
        <img
          className="invite-logo"
          src="/icons/Icon-512.png"
          alt={brand}
        />
        <h1>
          {isChooser
            ? labels.title
            : isNotFound
              ? labels.notFound
              : labels.preparing}
        </h1>
        <p>
          {isChooser
            ? labels.description
            : isNotFound
              ? labels.notFoundDescription
              : ''}
        </p>

        {isChooser && (
          <div className="form-link-actions">
            <a className="button" href={linkState.appUrl}>
              {labels.openApp}
            </a>
            <a className="button secondary" href={linkState.storeUrl}>
              {labels.getApp}
            </a>
            <button
              className="form-link-web-action"
              type="button"
              onClick={() => window.location.replace(linkState.webUrl)}
            >
              {labels.continueWeb}
            </button>
          </div>
        )}

        {isNotFound && (
          <a className="button" href="/">
            {labels.home}
          </a>
        )}
      </section>
    </main>
  );
}
