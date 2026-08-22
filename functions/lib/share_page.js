"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sharePage = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const COLLECTIONS = {
    petition: "petitions",
    poll: "polls",
    survey: "surveys",
};
function escapeHtml(value) {
    return value
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}
function compactText(value, fallback, maxLength) {
    if (typeof value !== "string")
        return fallback;
    const compact = value.replace(/\s+/g, " ").trim();
    if (!compact)
        return fallback;
    if (compact.length <= maxLength)
        return compact;
    return `${compact.slice(0, maxLength - 1).trimEnd()}…`;
}
function safeImageUrl(value, fallback) {
    if (typeof value !== "string")
        return fallback;
    try {
        const uri = new URL(value);
        return uri.protocol === "https:" ? uri.toString() : fallback;
    }
    catch (_) {
        return fallback;
    }
}
function requestHost(request) {
    var _a;
    const forwardedHost = (_a = request.get("x-forwarded-host")) === null || _a === void 0 ? void 0 : _a.split(",")[0].trim();
    return forwardedHost || request.get("host") || "stimmapp.net";
}
function webAppUrl(webOrigin, route) {
    if (!route)
        return webOrigin;
    return `${webOrigin}/?open=${encodeURIComponent(route)}`;
}
function isWebAppHost(host) {
    const hostname = host.toLowerCase().split(":")[0];
    return hostname === "web.stimmapp.net" || hostname === "web.vivot.net";
}
function renderShareShell({ locale, appName, formTitle, title, description, canonicalUrl, imageUrl, robots, route, isVivot, contentKind, }) {
    const safeFormTitle = escapeHtml(formTitle);
    const safeTitle = escapeHtml(title);
    const safeDescription = escapeHtml(description);
    const safeCanonicalUrl = escapeHtml(canonicalUrl);
    const safeImageUrlValue = escapeHtml(imageUrl);
    const safeAppName = escapeHtml(appName);
    const ogLocale = locale === "de" ? "de_DE" : "en_US";
    const webOrigin = isVivot
        ? "https://web.vivot.net"
        : "https://web.stimmapp.net";
    const appScheme = isVivot ? "vivot" : "stimmapp";
    // Firebase Hosting applies the form-path rewrite to every domain attached to
    // this site. Enter the Flutter web app through `/`, which is served by
    // index.html, and pass the intended form route separately. The app restores
    // the clean route after startup.
    const webUrl = webAppUrl(webOrigin, route);
    const appUrl = route ? `${appScheme}://${route.slice(1)}` : `${appScheme}://`;
    const labels = locale === "de" ? {
        heading: contentKind === "groupInvite" ?
            "Wie möchtest du diese Gruppeneinladung öffnen?" :
            "Wie möchtest du dieses Formular öffnen?",
        description: contentKind === "groupInvite" ?
            "Öffne sie in der App oder fahre direkt im Browser fort." :
            "Öffne es in der App oder fahre direkt im Browser fort.",
        openApp: "In der App öffnen",
        getApp: "App herunterladen",
        continueWeb: "Im Browser fortfahren",
    } : {
        heading: contentKind === "groupInvite" ?
            "How would you like to open this group invitation?" :
            "How would you like to open this form?",
        description: "Open it in the app or continue directly in your browser.",
        openApp: "Open in app",
        getApp: "Get the app",
        continueWeb: "Continue in browser",
    };
    return `<!DOCTYPE html>
<html lang="${locale}">
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${safeDescription}">
  <meta name="robots" content="${robots}">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="${ogLocale}">
  <meta property="og:site_name" content="${safeAppName}">
  <meta property="og:title" content="${safeTitle}">
  <meta property="og:description" content="${safeDescription}">
  <meta property="og:url" content="${safeCanonicalUrl}">
  <meta property="og:image" content="${safeImageUrlValue}">
  <meta property="og:image:secure_url" content="${safeImageUrlValue}">
  <meta property="og:image:alt" content="${safeFormTitle}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${safeTitle}">
  <meta name="twitter:description" content="${safeDescription}">
  <meta name="twitter:image" content="${safeImageUrlValue}">
  <link rel="canonical" href="${safeCanonicalUrl}">
  <link rel="apple-touch-icon" href="/icons/Icon-192.png">
  <link rel="icon" type="image/png" href="/favicon.png">
  <title>${safeTitle}</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      padding: 24px;
      color: #202124;
      background: #f7f8fa;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    main {
      width: min(100%, 430px);
      padding: 32px 24px;
      text-align: center;
      background: white;
      border-radius: 24px;
      box-shadow: 0 12px 36px rgba(0, 0, 0, .09);
    }
    img { width: 88px; height: 88px; border-radius: 22px; object-fit: cover; }
    h1 { margin: 22px 0 8px; font-size: 24px; line-height: 1.2; }
    .form-title { margin: 0 0 12px; font-weight: 650; }
    p { margin: 0 0 24px; color: #5f6368; line-height: 1.5; }
    .actions { display: grid; gap: 12px; }
    a {
      display: block;
      padding: 13px 18px;
      border-radius: 999px;
      color: white;
      background: #176b87;
      text-decoration: none;
      font-weight: 650;
    }
    a.secondary { color: #176b87; background: #eaf4f7; }
    a.plain { color: #176b87; background: transparent; }
  </style>
</head>
<body>
  <main>
    <img src="/icons/Icon-512.png" alt="${safeAppName}">
    <h1>${escapeHtml(labels.heading)}</h1>
    <div class="form-title">${safeFormTitle}</div>
    <p>${escapeHtml(labels.description)}</p>
    <div class="actions">
      <a href="${escapeHtml(appUrl)}">${escapeHtml(labels.openApp)}</a>
      <a class="secondary" id="store-link" href="https://play.google.com/store/apps/details?id=de.lemarq.stimmapp">${escapeHtml(labels.getApp)}</a>
      <a class="plain" href="${escapeHtml(webUrl)}">${escapeHtml(labels.continueWeb)}</a>
    </div>
  </main>
  <noscript><a href="${escapeHtml(webUrl)}">${escapeHtml(labels.continueWeb)}</a></noscript>
  <script>
    (() => {
      const mobile = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent)
        || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
      if (!mobile) {
        location.replace(${JSON.stringify(webUrl)});
        return;
      }
      const apple = /iPhone|iPad|iPod/i.test(navigator.userAgent)
        || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
      if (apple) {
        document.getElementById('store-link').href =
          'https://apps.apple.com/app/stimmapp/id6759249651';
      }
    })();
  </script>
</body>
</html>`;
}
exports.sharePage = (0, https_1.onRequest)(async (request, response) => {
    const formMatch = request.path.match(/^\/(petition|poll|survey)\/([^/?#]+)\/?$/);
    const isGroupInvite = /^\/group-invite\/?$/.test(request.path);
    const rawGroupId = Array.isArray(request.query.groupId) ?
        request.query.groupId[0] : request.query.groupId;
    const groupId = typeof rawGroupId === "string" ? rawGroupId : null;
    const validGroupId = groupId != null && /^[A-Za-z0-9_-]{1,128}$/.test(groupId);
    const host = requestHost(request);
    const isVivot = host.toLowerCase().includes("vivot");
    const webOrigin = isVivot
        ? "https://web.vivot.net"
        : "https://web.stimmapp.net";
    // A direct/reloaded Flutter web route also reaches this function because
    // Hosting rewrites are site-wide. Send it through the non-rewritten root
    // instead of rendering the share chooser on the web-app subdomain.
    if (isWebAppHost(host)) {
        const route = formMatch ?
            `/${formMatch[1]}/${encodeURIComponent(formMatch[2])}` :
            isGroupInvite && validGroupId ?
                `/group-invite?groupId=${encodeURIComponent(groupId)}` :
                null;
        response.set("Cache-Control", "private, no-store");
        response.redirect(302, webAppUrl(webOrigin, route));
        return;
    }
    const appName = isVivot ? "Vivot" : "StimmApp";
    const locale = isVivot ? "en" : "de";
    const genericDescription = isVivot
        ? "Create, share, and support petitions, polls, and surveys."
        : "Petitionen, Umfragen und Fragebögen erstellen, teilen und unterstützen.";
    const origin = `https://${host}`;
    const fallbackImage = `${origin}/icons/Icon-512.png`;
    let title = appName;
    let formTitle = appName;
    let description = genericDescription;
    let imageUrl = fallbackImage;
    let canonicalUrl = origin;
    let cacheControl = "public, max-age=60, s-maxage=300";
    let robots = "index,follow";
    let route = null;
    let contentKind = "form";
    if (formMatch) {
        const kind = formMatch[1];
        const id = formMatch[2];
        route = `/${kind}/${encodeURIComponent(id)}`;
        canonicalUrl = `${origin}${route}`;
        if (/^[A-Za-z0-9_-]{1,128}$/.test(id)) {
            try {
                const snapshot = await admin
                    .firestore()
                    .collection(COLLECTIONS[kind])
                    .doc(id)
                    .get();
                const data = snapshot.data();
                const isPublic = snapshot.exists && (data === null || data === void 0 ? void 0 : data.visibility) !== "group";
                if (isPublic && data) {
                    formTitle = compactText(data.title, appName, 120);
                    title = formTitle;
                    description = compactText(data.description, genericDescription, 220);
                    imageUrl = safeImageUrl(data.imageUrl, fallbackImage);
                }
                else {
                    cacheControl = "private, no-store";
                    robots = "noindex,nofollow";
                }
            }
            catch (error) {
                console.error(`[sharePage] Failed to load ${kind}/${id}`, error);
                cacheControl = "private, no-store";
                robots = "noindex,nofollow";
            }
        }
        else {
            cacheControl = "private, no-store";
            robots = "noindex,nofollow";
        }
    }
    else if (isGroupInvite) {
        contentKind = "groupInvite";
        cacheControl = "private, no-store";
        robots = "noindex,nofollow";
        formTitle = appName;
        title = locale === "de" ? "Gruppeneinladung" : "Group invitation";
        description = locale === "de" ?
            `Öffne diese Gruppeneinladung mit ${appName}.` :
            `Open this group invitation with ${appName}.`;
        if (validGroupId) {
            route = `/group-invite?groupId=${encodeURIComponent(groupId)}`;
            canonicalUrl = `${origin}${route}`;
        }
    }
    response.set("Content-Type", "text/html; charset=utf-8");
    response.set("Cache-Control", cacheControl);
    response.set("X-Content-Type-Options", "nosniff");
    response.status(200).send(renderShareShell({
        locale,
        appName,
        formTitle,
        title,
        description,
        canonicalUrl,
        imageUrl,
        robots,
        route,
        isVivot,
        contentKind,
    }));
});
//# sourceMappingURL=share_page.js.map