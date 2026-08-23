import de from '../messages/de.json';
import en from '../messages/en.json';
import SiteFooter from './site-footer';
import SiteHeader from './site-header';
import styles from './subpage-shell.module.css';

const copyByLocale = { de, en };

export default function SubpageShell({ children, locale = 'de', centered = false }) {
  const copy = copyByLocale[locale] ?? de;

  return (
    <div className={styles.scroller}>
      <div className={styles.frame}>
        <SiteHeader copy={copy} />
        <main className={`${styles.main}${centered ? ` ${styles.centered}` : ''}`}>
          {children}
        </main>
        <SiteFooter copy={copy} />
      </div>
    </div>
  );
}
