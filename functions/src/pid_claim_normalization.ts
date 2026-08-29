function compactWhitespace(value: string) {
  return value.trim().replace(/\s+/g, ' ');
}

/**
 * Converts the all-uppercase display form commonly used by identity documents
 * into a profile-friendly form. Mixed-case values are preserved because their
 * casing may be intentional (for example, McDonald or de Vries).
 */
export function normalizePidDisplayText(value: string | null) {
  if (value === null) return null;

  const compact = compactWhitespace(value);
  if (!compact || compact !== compact.toLocaleUpperCase('de-DE') ||
      compact === compact.toLocaleLowerCase('de-DE')) {
    return compact || null;
  }

  return compact
    .split(/([\s'-]+)/)
    .map((part) => {
      const lower = part.toLocaleLowerCase('de-DE');
      return lower.length === 0 ? lower :
        lower[0].toLocaleUpperCase('de-DE') + lower.slice(1);
    })
    .join('');
}

export function normalizePidPostalCode(value: string | null) {
  if (value === null) return null;
  const compact = compactWhitespace(value).toLocaleUpperCase('de-DE');
  return compact || null;
}

export function formatPidProfileAddress({
  streetAddress,
  postalCode,
  locality,
}: {
  streetAddress: string | null;
  postalCode: string | null;
  locality: string | null;
}) {
  const postalLocality = [postalCode, locality].filter(Boolean).join(' ');
  const parts = [streetAddress, postalLocality || null].filter(Boolean);
  return parts.length > 0 ? parts.join(', ') : null;
}
