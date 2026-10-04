import Link from 'next/link';
import FormImportGuide from './form-import-guide';
import documentStyles from './content-page.module.css';
import styles from './documentation.module.css';

export default function Documentation({ copy, locale, format = 'json' }) {
  const docs = copy.documentation;
  const root = locale === 'en' ? '/documentation' : '/dokumentation';
  const section = locale === 'en' ? 'import-forms' : 'formulare-importieren';
  const guideUrl = (type) => `${root}/${section}/${type}`;

  return (
    <div className={styles.layout}>
      <aside className={styles.sidebar}>
        <Link className={styles.libraryTitle} href={root}>{docs.heading}</Link>
        <nav aria-label={docs.navigation}>
          <Link className={styles.navItem} href={root} aria-current={format === null ? 'page' : undefined}>{docs.overview}</Link>
          <p className={styles.category}>{docs.category}</p>
          <div className={styles.group}>
            <span className={styles.groupTitle}>{docs.importHeading}</span>
            {['json', 'pdf'].map((type) => (
              <Link key={type} className={styles.navItem} href={guideUrl(type)} aria-current={format === type ? 'page' : undefined}>
                {type.toUpperCase()}
              </Link>
            ))}
          </div>
        </nav>
      </aside>
      <div className={styles.content}>
        {format === null ? (
          <article className={documentStyles.document}>
            <p className={styles.eyebrow}>StimmApp · {docs.heading}</p>
            <h1>{docs.heading}</h1>
            <p className={styles.intro}>{docs.intro}</p>
            <h2>{docs.importHeading}</h2>
            <p>{docs.importIntro}</p>
            <div className={styles.cards}>
              {['json', 'pdf'].map((type) => (
                <Link className={styles.guideCard} key={type} href={guideUrl(type)}>
                  <span className={styles.format}>{type.toUpperCase()}</span>
                  <h3>{copy.guides[type].heading}</h3>
                  <p>{docs[`${type}Summary`]}</p>
                  <span className={styles.readGuide}>{docs.readGuide} →</span>
                </Link>
              ))}
            </div>
          </article>
        ) : (
          <>
            <div className={styles.breadcrumb}>
              <Link href={root}>{docs.heading}</Link><span aria-hidden="true">/</span>
              <span>{docs.importHeading}</span><span aria-hidden="true">/</span><span>{format.toUpperCase()}</span>
            </div>
            <FormImportGuide copy={copy} locale={locale} format={format} embedded />
          </>
        )}
      </div>
    </div>
  );
}
