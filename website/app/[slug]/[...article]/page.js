import { notFound } from 'next/navigation';
import ContentPage from '../../../components/content-page';
import de from '../../../messages/de.json';
import en from '../../../messages/en.json';

const locales = {
  dokumentation: { locale: 'de', section: 'formulare-importieren' },
  documentation: { locale: 'en', section: 'import-forms' },
};
const messages = { de, en };
export const dynamicParams = false;

export function generateStaticParams() {
  return Object.entries(locales).flatMap(([slug, { section }]) =>
    ['json', 'pdf'].map((format) => ({ slug, article: [section, format] })),
  );
}

function resolveRoute(slug, article) {
  const route = locales[slug];
  if (!route || article.length !== 2 || article[0] !== route.section || !['json', 'pdf'].includes(article[1])) return null;
  return { locale: route.locale, format: article[1] };
}

export async function generateMetadata({ params }) {
  const { slug, article } = await params;
  const route = resolveRoute(slug, article);
  if (!route) return {};
  const copy = messages[route.locale].pages.formImport;
  return { title: copy.guides[route.format].title, description: copy.description };
}

export default async function DocumentationArticle({ params }) {
  const { slug, article } = await params;
  const route = resolveRoute(slug, article);
  if (!route) notFound();
  return <ContentPage page="formImport" explicitLocale={route.locale} format={route.format} messages={{ de: de.pages.formImport, en: en.pages.formImport }} />;
}
