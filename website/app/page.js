'use client';

import { useEffect, useState } from 'react';
import Spline from '@splinetool/react-spline';
import SiteFooter from '../components/site-footer';
import SiteHeader from '../components/site-header';
import de from '../messages/de.json';
import en from '../messages/en.json';

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
          src="/images/3d-background.png"
          alt=""
        />
        {canUseWebGL && (
          <Spline
            className={`page-background-scene${isSplineLoaded ? ' is-loaded' : ''}`}
            scene="https://prod.spline.design/wqR9pdHZ2Tj-IT5l/scene.splinecode"
            onLoad={(spline) => {
              setIsSplineLoaded(true);
            }}
          />
        )}
      </div>

      <div className="shell">
      <SiteHeader copy={copy} />

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
                  <a
                    className="contact-action contact-action-email"
                    href="mailto:info@trainvent.com"
                    aria-label={`${copy.contactEmailAction}: info@trainvent.com`}
                  >
                    <span className="contact-action-icon" aria-hidden="true">
                      <svg viewBox="0 0 24 24" focusable="false">
                        <path d="M4 6.5h16v11H4z" />
                        <path d="m5 7.5 7 5 7-5" />
                      </svg>
                    </span>
                    <span className="contact-action-copy">
                      <span className="contact-action-title">{copy.contactEmailAction}</span>
                      <span className="contact-action-detail">info@trainvent.com</span>
                    </span>
                    <span className="contact-action-arrow" aria-hidden="true">→</span>
                  </a>
                  <a
                    className="contact-action contact-action-form"
                    href={copy.contactButtonHref}
                  >
                    <span className="contact-action-icon" aria-hidden="true">
                      <svg viewBox="0 0 24 24" focusable="false">
                        <path d="M7 3.5h10a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-13a2 2 0 0 1 2-2Z" />
                        <path d="M8.5 8h7M8.5 12h7M8.5 16h4" />
                      </svg>
                    </span>
                    <span className="contact-action-copy">
                      <span className="contact-action-title">{copy.contactButton}</span>
                      <span className="contact-action-detail">{copy.contactFormDetail}</span>
                    </span>
                    <span className="contact-action-arrow" aria-hidden="true">↗</span>
                  </a>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      <SiteFooter copy={copy} />
      </div>
    </div>
  );
}
