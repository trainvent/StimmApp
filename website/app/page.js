'use client';

import { useEffect, useState } from 'react';
import Spline from '@splinetool/react-spline';
import de from '../public/i18n/de.json';
import en from '../public/i18n/en.json';

const copyByHost = {
  de,
  en,
};

function currentCopy() {
  if (typeof window === 'undefined') {
    return copyByHost.de;
  }

  return window.location.hostname.toLowerCase().includes('vivot.net')
    ? copyByHost.en
    : copyByHost.de;
}

export default function HomePage() {
  const [copy, setCopy] = useState(copyByHost.de);
  const [canUseWebGL, setCanUseWebGL] = useState(null);
  const [isSplineLoaded, setIsSplineLoaded] = useState(false);
  const isEnglish = copy.lang === 'en';
  const playBadgeSrc = isEnglish
    ? '/store-badges/google-play-en.svg'
    : '/store-badges/google-play-de.svg';
  const appStoreBadgeSrc = isEnglish
    ? '/store-badges/app-store-en.svg'
    : '/store-badges/app-store-de.svg';

  useEffect(() => {
    const nextCopy = currentCopy();
    setCopy(nextCopy);
    document.documentElement.lang = nextCopy.lang;
    document.title = nextCopy.title;

    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) {
      metaDescription.setAttribute('content', nextCopy.description);
    }

    const canvas = document.createElement('canvas');
    const context = canvas.getContext('webgl2') || canvas.getContext('webgl');
    setCanUseWebGL(Boolean(context));

    context?.getExtension('WEBGL_lose_context')?.loseContext();
  }, []);

  return (
    <div className="page">
      <div className="page-background" aria-hidden="true">
        <img
          className={`page-background-fallback${canUseWebGL === false ? ' is-visible' : ''}`}
          src="/3d_background.png"
          alt=""
        />
        {canUseWebGL && (
          <Spline
            className={`page-background-scene${isSplineLoaded ? ' is-loaded' : ''}`}
            scene="https://prod.spline.design/wqR9pdHZ2Tj-IT5l/scene.splinecode"
            onLoad={(spline) => {
              const camera = spline.findObjectByName('Camera');

              if (camera) {
                camera.state = 'Top';
              }

              setIsSplineLoaded(true);
            }}
          />
        )}
      </div>

      <div className="shell">
      <header className="nav">
        <a className="brand" href="./">
          <img className="brand-mark" src="icons/Icon-512.png" alt={copy.logoAlt} />
          <span>{copy.brand}</span>
        </a>
        <nav className="nav-links">
          <a className="button" href={copy.appUrl}>{copy.navOpenApp}</a>
        </nav>
      </header>

      <main>
        <section className="hero">
          <div className="hero-stack">
            <div className="hero-copy">
              <h1>{copy.heroTitle}</h1>
              <p className="lede">{copy.heroLede}</p>
              <div className="cta-row">
                <a
                  className="store-badge-link"
                  href="https://play.google.com/store/apps/details?id=de.lemarq.stimmapp"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <img className="store-badge" src={playBadgeSrc} alt={copy.heroPlayStore} />
                </a>
                <a
                  className="store-badge-link"
                  href="https://apps.apple.com/app/stimmapp/id6759249651"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <img className="store-badge" src={appStoreBadgeSrc} alt={copy.heroAppStore} />
                </a>
              </div>
            </div>

            <div className="micro-list">
              <div className="micro-card micro-card-support">
                <strong>{copy.microSupportTitle}</strong>
                <span>{copy.microSupportText}</span>
              </div>
              <div className="micro-card micro-card-contact">
                <strong>{copy.contactTitle}</strong>
                <div className="micro-card-actions">
                  <a href="mailto:info@trainvent.com">info@trainvent.com</a>
                  <a href={copy.contactButtonHref}>{copy.contactButton}</a>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="footer">
        <div className="footer-meta">
          <p className="footer-subservice">
            {copy.footerSubserviceText}{' '}
            <a href="https://next.trainvent.com/" target="_blank" rel="noreferrer">
              {copy.footerSubserviceLink}
            </a>
          </p>
        </div>
        <div className="footer-links">
          <a href="privacy_policy.html">{copy.footerPrivacy}</a>
          <a href="terms-of-service.html">{copy.footerTerms}</a>
          <a href="support.html">{copy.footerSupport}</a>
          <a href="faq.html">FAQ</a>
        </div>
      </footer>
      </div>
    </div>
  );
}
