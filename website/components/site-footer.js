import Link from 'next/link';

export default function SiteFooter({ copy }) {
  const isEnglish = copy.lang === 'en';

  return (
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
        <Link href={isEnglish ? '/privacy-policy' : '/datenschutzerklaerung'}>{copy.footerPrivacy}</Link>
        <Link href={isEnglish ? '/terms-of-service' : '/nutzungsbedingungen'}>{copy.footerTerms}</Link>
        <Link href="/support">{copy.footerSupport}</Link>
        <Link href="/faq">FAQ</Link>
      </div>
    </footer>
  );
}
