'use client';

import { useEffect, useState } from 'react';
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
          <div className="hero-grid">
            <div className="hero-copy">
              <div className="eyebrow">{copy.heroEyebrow}</div>
              <h1>{copy.heroTitle}</h1>
              <p className="lede">{copy.heroLede}</p>
              <div className="cta-row">
                <a
                  className="button secondary"
                  href="https://play.google.com/store/apps/details?id=de.lemarq.stimmapp"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {copy.heroPlayStore}
                </a>
                <a
                  className="button secondary"
                  href="https://apps.apple.com/app/stimmapp/id6759249651"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {copy.heroAppStore}
                </a>
              </div>
              <div className="micro-list">
                <div className="micro-card">
                  <strong>{copy.microTitle}</strong>
                  <span>{copy.microText}</span>
                </div>
                <a className="micro-card micro-card-link" href={copy.microSupportHref}>
                  <strong>{copy.microSupportTitle}</strong>
                  <span>{copy.microSupportText}</span>
                </a>
              </div>
            </div>

            <aside className="hero-panel" aria-label="Product preview">
              <div className="mock-card">
                <div className="mock-head">
                  <strong>{copy.panelOneTitle}</strong>
                  <div className="dot-group">
                    <span className="dot" style={{ background: '#164f2b' }} />
                    <span className="dot" style={{ background: '#1570ef' }} />
                    <span className="dot" style={{ background: '#f4b740' }} />
                  </div>
                </div>
                <div className="mock-row">
                  <span>{copy.panelOneRowOneLabel}</span>
                  <strong>{copy.panelOneRowOneValue}</strong>
                </div>
                <div className="bar"><span style={{ width: '82%' }} /></div>
                <div className="mock-row top-gap">
                  <span>{copy.panelOneRowTwoLabel}</span>
                  <strong>{copy.panelOneRowTwoValue}</strong>
                </div>
                <div className="bar">
                  <span
                    style={{
                      width: '90%',
                      background: 'linear-gradient(90deg, #1570ef, #6ea9ff)',
                    }}
                  />
                </div>
              </div>

              <div className="mock-card">
                <div className="mock-head">
                  <strong>{copy.panelTwoTitle}</strong>
                  <span className="muted">{copy.panelTwoKicker}</span>
                </div>
                <div className="mock-row">
                  <span>{copy.panelTwoRowOneLabel}</span>
                  <strong>e-ID</strong>
                </div>
                <div className="bar"><span style={{ width: '72%' }} /></div>
                <div className="mock-row top-gap">
                  <span>{copy.panelTwoRowTwoLabel}</span>
                  <strong>{copy.panelTwoRowTwoValue}</strong>
                </div>
                <div className="bar">
                  <span
                    style={{
                      width: '78%',
                      background: 'linear-gradient(90deg, #f4b740, #f7cf75)',
                    }}
                  />
                </div>
              </div>

              <div className="panel-note">
                <strong>{copy.panelNoteTitle}</strong>
                <p>{copy.panelNoteText}</p>
                <a className="button secondary" href="#contact" onClick={scrollToContact}>{copy.heroContact}</a>
              </div>
            </aside>
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
                <a href="mailto:hello@trainvent.com">hello@trainvent.com</a>
              </p>
              <p>{copy.contactText}</p>
              <div className="cta-row contact-row">
                <a className="button" href={copy.contactButtonHref}>{copy.contactButton}</a>
                <a className="button secondary" href={copy.appUrl}>{copy.contactOpenApp}</a>
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
  );
}
