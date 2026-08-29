"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.normalizePidDisplayText = normalizePidDisplayText;
exports.normalizePidPostalCode = normalizePidPostalCode;
exports.formatPidProfileAddress = formatPidProfileAddress;
function compactWhitespace(value) {
    return value.trim().replace(/\s+/g, ' ');
}
/**
 * Converts the all-uppercase display form commonly used by identity documents
 * into a profile-friendly form. Mixed-case values are preserved because their
 * casing may be intentional (for example, McDonald or de Vries).
 */
function normalizePidDisplayText(value) {
    if (value === null)
        return null;
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
function normalizePidPostalCode(value) {
    if (value === null)
        return null;
    const compact = compactWhitespace(value).toLocaleUpperCase('de-DE');
    return compact || null;
}
function formatPidProfileAddress({ streetAddress, postalCode, locality, }) {
    const postalLocality = [postalCode, locality].filter(Boolean).join(' ');
    const parts = [streetAddress, postalLocality || null].filter(Boolean);
    return parts.length > 0 ? parts.join(', ') : null;
}
//# sourceMappingURL=pid_claim_normalization.js.map