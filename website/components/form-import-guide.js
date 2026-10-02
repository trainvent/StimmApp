import pollEn from '../public/examples/poll-import-en.json';
import pollDe from '../public/examples/poll-import-de.json';
import styles from './content-page.module.css';

export default function FormImportGuide({ copy, locale }) {
  const example = locale === 'en' ? pollEn : pollDe;
  return (
    <article className={`${styles.document} ${styles.card}`}>
      <h1>{copy.heading}</h1>
      <p>{copy.intro}</p>
      <h2>{copy.stepsHeading}</h2>
      <ol>{copy.steps.map((step) => <li key={step}>{step}</li>)}</ol>
      <h2>{copy.examplesHeading}</h2>
      <ul>
        <li><a href={`/examples/poll-import-${locale}.json`} download>{copy.pollDownload}</a></li>
        <li><a href={`/examples/petition-import-${locale}.json`} download>{copy.petitionDownload}</a></li>
      </ul>
      <p>{copy.exampleHint}</p>
      <pre className={styles.jsonExample}><code>{JSON.stringify(example, null, 2)}</code></pre>
      <h2>{copy.fieldsHeading}</h2>
      <div className={styles.tableScroll} role="region" aria-label={copy.fieldsHeading} tabIndex={0}>
        <table className={styles.fieldTable}>
          <thead><tr><th scope="col">{copy.fieldLabel}</th><th scope="col">{copy.ruleLabel}</th></tr></thead>
          <tbody>{copy.fields.map(([field, rule]) => <tr key={field}><th scope="row"><code>{field}</code></th><td>{rule}</td></tr>)}</tbody>
        </table>
      </div>
      <h2>{copy.settingsHeading}</h2>
      <p>{copy.settings}</p>
      <h2>{copy.tagsHeading}</h2>
      <ul className={styles.tagKeys}>{copy.tags.map((tag) => <li key={tag}><code>{tag}</code></li>)}</ul>
      <h2>{copy.errorsHeading}</h2>
      <p>{copy.errors}</p>
    </article>
  );
}
