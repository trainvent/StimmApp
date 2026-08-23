import { notFound } from 'next/navigation';
import ContentPage from '../../components/content-page';
import { contentRoutes, contentRouteSlugs } from '../../lib/content-routes.mjs';
import de from '../../messages/de.json';
import en from '../../messages/en.json';

const messages = { de, en };

export const dynamicParams = false;

export function generateStaticParams() {
  return contentRouteSlugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }) {
  const { slug } = await params;
  const route = contentRoutes[slug];
  if (!route) return {};

  const locale = route.locale ?? 'de';
  const copy = messages[locale].pages[route.page];
  return {
    title: copy.title,
    description: copy.description,
  };
}

export default async function StaticContentRoute({ params }) {
  const { slug } = await params;
  const route = contentRoutes[slug];
  if (!route) notFound();

  return (
    <ContentPage
      page={route.page}
      explicitLocale={route.locale}
      messages={{ de: de.pages[route.page], en: en.pages[route.page] }}
    />
  );
}
