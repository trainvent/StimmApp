'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useEffect, useState } from 'react';
import styles from './content-page.module.css';
import SubpageShell from './subpage-shell';

const FIREBASE_API_KEY = 'AIzaSyD8neBcTS2fkkRJf_GG-l4hD5dGArstQW8';

function useLocale(explicitLocale) {
  const [locale, setLocale] = useState(explicitLocale ?? 'de');

  useEffect(() => {
    const nextLocale =
      explicitLocale ??
      (window.location.hostname.toLowerCase().includes('vivot.net') ? 'en' : 'de');
    setLocale(nextLocale);
    document.documentElement.lang = nextLocale;
  }, [explicitLocale]);

  return locale;
}

function PrivacyPolicy({ copy }) {
  return (
    <article className={styles.document}>
      <h1>{copy.heading}</h1>
      <p><strong>{copy.dateLabel}</strong> {copy.date}</p>
      <p>{copy.intro}</p>
      <h2>{copy.overviewHeading}</h2>
      <p>{copy.overviewPurpose}</p>
      <p>{copy.overviewAds}</p>
      <p>{copy.overviewData}</p>
      <h2>{copy.noticesHeading}</h2>
      <p>{copy.noticesIntro}</p>
      <ul><li><Link href={copy.crashDataUrl}>{copy.crashDataLink}</Link></li></ul>
      <h2>{copy.thirdPartiesHeading}</h2>
      <p>{copy.thirdParties}</p>
      <ul>
        <li><a href="https://www.google.com/policies/privacy/" target="_blank" rel="noreferrer">Google Play Services</a></li>
        <li><a href="https://firebase.google.com/support/privacy" target="_blank" rel="noreferrer">Firebase</a></li>
      </ul>
      <h2>{copy.providersHeading}</h2>
      <p>{copy.providers}</p>
      <h2>{copy.securityHeading}</h2>
      <p>{copy.security}</p>
      <h2>{copy.linksHeading}</h2>
      <p>{copy.links}</p>
      <h2>{copy.childrenHeading}</h2>
      <p>{copy.children}</p>
      <h2>{copy.changesHeading}</h2>
      <p>{copy.changes}</p>
      <h2>{copy.contactHeading}</h2>
      <p>{copy.contact} <a href="mailto:support@trainvent.com">support@trainvent.com</a>.</p>
    </article>
  );
}

function PrivacyPolicyCrashData({ copy }) {
  return (
    <article className={styles.document}>
      <h1>{copy.heading}</h1>
      <p><strong>{copy.dateLabel}</strong> {copy.date}</p>
      <p>{copy.intro}</p>
      <h2>{copy.dataHeading}</h2>
      <p>{copy.data}</p>
      <h2>{copy.purposeHeading}</h2>
      <p>{copy.purpose}</p>
      <h2>{copy.choiceHeading}</h2>
      <p>{copy.choice}</p>
      <h2>{copy.providersHeading}</h2>
      <p>{copy.providers}</p>
      <h2>{copy.retentionHeading}</h2>
      <p>{copy.retention}</p>
      <h2>{copy.contactHeading}</h2>
      <p>{copy.contact} <a href="mailto:support@trainvent.com">support@trainvent.com</a>.</p>
    </article>
  );
}

function TermsOfService({ copy }) {
  return (
    <article className={`${styles.document} ${styles.card}`}>
      <h1>{copy.heading}</h1>
      <p>{copy.intro}</p>
      <h2>{copy.purposeHeading}</h2><p>{copy.purpose}</p>
      <h2>{copy.responsibleUseHeading}</h2><p>{copy.responsibleUse}</p>
      <h2>{copy.enforcementHeading}</h2><p>{copy.enforcement}</p>
      <h2>{copy.accountHeading}</h2><p>{copy.account}</p>
      <h2>{copy.changesHeading}</h2><p>{copy.changes}</p>
      <h2>{copy.licenseHeading}</h2><p>{copy.license}</p>
      <p><Link href="/license">{copy.licenseLink}</Link></p>
      <h2>{copy.contactHeading}</h2>
      <p>{copy.contact} <a href="mailto:support@trainvent.com">support@trainvent.com</a></p>
      <p><Link href="/support">{copy.supportLink}</Link></p>
    </article>
  );
}

function Faq({ copy, locale }) {
  const privacyUrl = locale === 'de' ? '/datenschutzerklaerung' : '/privacy-policy';
  const termsUrl = locale === 'de' ? '/nutzungsbedingungen' : '/terms-of-service';
  return (
    <article className={`${styles.document} ${styles.card}`}>
      <h1>{copy.heading}</h1>
      <h2>{copy.questionDelete}</h2>
      <p>{copy.answerDeletePrefix} <Link href="/delete-account">{copy.deleteLink}</Link> {copy.answerDeleteMiddle} <a href="mailto:support@trainvent.com">support@trainvent.com</a>.</p>
      <h2>{copy.questionTechnical}</h2>
      <p>{copy.answerTechnical}</p>
      <h2>{copy.questionLegal}</h2>
      <p><Link href={privacyUrl}>{copy.privacyLink}</Link><br /><Link href={termsUrl}>{copy.termsLink}</Link></p>
      <p><Link href="/support">{copy.backLink}</Link></p>
    </article>
  );
}

function Support({ copy, locale }) {
  const privacyUrl = locale === 'de' ? '/datenschutzerklaerung' : '/privacy-policy';
  const termsUrl = locale === 'de' ? '/nutzungsbedingungen' : '/terms-of-service';
  return (
    <article className={`${styles.document} ${styles.card}`}>
      <h1>{copy.heading}</h1>
      <p>{copy.intro}</p>
      <p><strong>{copy.emailLabel}</strong> <a href="mailto:support@trainvent.com">support@trainvent.com</a></p>
      <h2>{copy.linksHeading}</h2>
      <ul>
        <li><Link href="/faq">FAQ</Link></li>
        <li><Link href={privacyUrl}>{copy.privacyLink}</Link></li>
        <li><Link href={termsUrl}>{copy.termsLink}</Link></li>
        <li><Link href="/license">{copy.licenseLink}</Link></li>
        <li><Link href="/delete-account">{copy.deleteLink}</Link></li>
      </ul>
      <h2>{copy.messageHeading}</h2>
      <ul><li>{copy.messageEmail}</li><li>{copy.messageDevice}</li><li>{copy.messageDescription}</li></ul>
      <p className={styles.meta}>{copy.meta}</p>
    </article>
  );
}

function License({ copy }) {
  return (
    <article className={`${styles.document} ${styles.card}`}>
      <h1>{copy.heading}</h1>
      <p>{copy.introPrefix} <strong>GNU General Public License v3.0</strong>.</p>
      <p><strong>SPDX:</strong> <code>GPL-3.0-only</code></p>
      <p>{copy.fullText}</p>
      <p><a href="https://www.gnu.org/licenses/gpl-3.0.txt" target="_blank" rel="noreferrer">{copy.licenseTextLink}</a></p>
      <p>{copy.contact} <a href="mailto:info@trainvent.com">info@trainvent.com</a></p>
      <p><Link href="/support">{copy.backLink}</Link></p>
    </article>
  );
}

function Marketing({ copy }) {
  return (
    <main className={styles.marketingCard}>
      <Image className={styles.logo} src="/icons/Icon-512.png" alt={copy.logoAlt} width={104} height={104} />
      <h1>{copy.title}</h1>
      <p>{copy.tagline}</p>
      <div className={styles.actions}>
        <a className={styles.primaryButton} href="https://apps.apple.com/app/stimmapp/id6759249651" target="_blank" rel="noreferrer">{copy.appStore}</a>
        <a className={styles.secondaryButton} href="https://play.google.com/store/apps/details?id=de.lemarq.stimmapp" target="_blank" rel="noreferrer">{copy.playStore}</a>
      </div>
    </main>
  );
}

function firebaseErrorCode(message) {
  if (['EMAIL_NOT_FOUND', 'INVALID_PASSWORD', 'INVALID_LOGIN_CREDENTIALS'].includes(message)) return 'invalidCredentials';
  if (message?.startsWith('TOO_MANY_ATTEMPTS')) return 'tooManyRequests';
  return 'unknownError';
}

function DeleteAccount({ copy }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);
  const [isDeleted, setIsDeleted] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setError('');
    setIsDeleting(true);
    try {
      const signInResponse = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, returnSecureToken: true }),
      });
      const signInData = await signInResponse.json();
      if (!signInResponse.ok) throw new Error(signInData.error?.message);

      const deleteResponse = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${FIREBASE_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken: signInData.idToken }),
      });
      const deleteData = await deleteResponse.json();
      if (!deleteResponse.ok) throw new Error(deleteData.error?.message);
      setIsDeleted(true);
    } catch (exception) {
      const key = firebaseErrorCode(exception.message);
      setError(`${copy.errorPrefix} ${copy[key]}${key === 'unknownError' && exception.message ? ` (${exception.message})` : ''}`);
    } finally {
      setIsDeleting(false);
    }
  }

  if (isDeleted) {
    return <section className={`${styles.document} ${styles.center}`}><h1>{copy.successHeading}</h1><p>{copy.successCopy}</p></section>;
  }

  return (
    <section className={styles.document}>
      <h1>{copy.heading}</h1>
      <p>{copy.intro}</p>
      {error && <p className={styles.error} role="alert">{error}</p>}
      <form onSubmit={submit}>
        <label className={styles.field}>{copy.emailLabel}<input type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" required /></label>
        <label className={styles.field}>{copy.passwordLabel}<input type="password" value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" required /></label>
        <p className={styles.warning}>{copy.warning}</p>
        <button className={styles.deleteButton} type="submit" disabled={isDeleting}>{isDeleting ? copy.deletingButton : copy.deleteButton}</button>
      </form>
    </section>
  );
}

const pageComponents = {
  deleteAccount: DeleteAccount,
  faq: Faq,
  license: License,
  marketing: Marketing,
  privacyPolicy: PrivacyPolicy,
  privacyPolicyCrashData: PrivacyPolicyCrashData,
  support: Support,
  termsOfService: TermsOfService,
};

export default function ContentPage({ page, explicitLocale, messages }) {
  const locale = useLocale(explicitLocale);
  const copy = messages[locale];
  const PageComponent = pageComponents[page];

  useEffect(() => {
    document.title = copy.title;
    if (copy.description) {
      let meta = document.querySelector('meta[name="description"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.name = 'description';
        document.head.appendChild(meta);
      }
      meta.content = copy.description;
    }
  }, [copy]);

  return (
    <SubpageShell locale={locale} centered={page === 'marketing'}>
      <PageComponent copy={copy} locale={locale} />
    </SubpageShell>
  );
}
