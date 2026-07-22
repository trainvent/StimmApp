'use client';

import { useEffect, useState } from 'react';
import Spline from '@splinetool/react-spline/next';
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
  const [isSplineLoaded, setIsSplineLoaded] = useState(false);
  const isEnglish = copy.lang === 'en';
  const playBadgeSrc = isEnglish
    ? '/store-badges/google-play-en.svg'
    : '/store-badges/google-play-de.svg';
  const appStoreBadgeSrc = isEnglish
    ? '/store-badges/app-store-en.svg'
    : '/store-badges/app-store-de.svg';

  const scrollToContact = (event) => {
    event.preventDefault();
    const contactSection = document.getElementById('contact');
    if (contactSection) {
      contactSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  useEffect(() => {
    const nextCopy = currentCopy();
    setCopy(nextCopy);
    document.documentElement.lang = nextCopy.lang;
    document.title = nextCopy.title;

    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) {
      metaDescription.setAttribute('content', nextCopy.description);
    }
  }, []);

  return (
    <>
      <div className="page-background" aria-hidden="true">
        <img
          className={`page-background-fallback${isSplineLoaded ? ' is-hidden' : ''}`}
          src="/3d_background.png"
          alt=""
        />
        <Spline
          className={`page-background-scene${isSplineLoaded ? ' is-loaded' : ''}`}
          scene="https://prod.spline.design/wqR9pdHZ2Tj-IT5l/scene.splinecode"
          onLoad={() => setIsSplineLoaded(true)}
        />
      </div>

      <div className="shell">
      <header className="nav">
        <a className="brand" href="./">
          <img className="brand-mark" src="icons/Icon-512.png" alt={copy.logoAlt} />
          <span>{copy.brand}</span>
        </a>
        <nav className="nav-links">
          <a className="nav-link" href="#mission">{copy.navMission}</a>
          <a className="nav-link" href="#contact" onClick={scrollToContact}>{copy.navContact}</a>
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
              <a
                className="micro-card"
                href="#contact"
                onClick={scrollToContact}
                role="button"
              >
                <strong>{copy.microSupportTitle}</strong>
                <span>{copy.microSupportText}</span>
              </a>
            </div>
          </div>
        </section>

        <section className="section" id="mission">
          <div className="section-grid">
            <article className="section-card">
              <span className="kicker">{copy.missionCardOneKicker}</span>
              <h2>{copy.missionCardOneTitle}</h2>
              <p>{copy.missionCardOneText}</p>
            </article>
            <article className="section-card">
              <span className="kicker">{copy.missionCardTwoKicker}</span>
              <h2>{copy.missionCardTwoTitle}</h2>
              <p>{copy.missionCardTwoText}</p>
            </article>
            <article className="section-card">
              <span className="kicker">{copy.missionCardThreeKicker}</span>
              <h2>{copy.missionCardThreeTitle}</h2>
              <p>{copy.missionCardThreeText}</p>
            </article>
          </div>
        </section>

        <section className="section">
          <div className="story">
            <article className="section-card">
              <span className="kicker">{copy.storyOneKicker}</span>
              <h3>{copy.storyOneTitle}</h3>
              <p>{copy.storyOneText}</p>
              <ul>
                <li>{copy.storyListOne}</li>
                <li>{copy.storyListTwo}</li>
                <li>{copy.storyListThree}</li>
              </ul>
            </article>
            <article id="contact" className="section-card">
              <span className="kicker">{copy.contactKicker}</span>
              <h3>{copy.contactTitle}</h3>
              <p>
                <span>{copy.contactEmailLabel}</span>{' '}
                <a href="mailto:info@trainvent.com">info@trainvent.com</a>
              </p>
              <p>{copy.contactText}</p>
              <div className="cta-row contact-row">
                <a className="button" href={copy.contactButtonHref}>{copy.contactButton}</a>
              </div>
            </article>
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
    </>
  );
}
