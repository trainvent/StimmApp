/** The public callback confirms receipt, never verification or profile saving. */
export function pidResultPage(returnUrl: string, language: 'de' | 'en') {
  const text = language === 'de' ? {
    title: 'Zurück zur Identitätsprüfung',
    body: 'Kehre zur App zurück, um das Ergebnis zu prüfen und deine Angaben zu bestätigen. Auf dieser Seite werden keine Profildaten gespeichert.',
    waiting: 'Die App wird in wenigen Sekunden geöffnet …',
    link: 'Jetzt zur App zurückkehren',
    recovery: 'Falls die App nicht geöffnet wird, öffne sie selbst und rufe die Identitätsprüfung auf. Dort kannst du den Status prüfen oder erneut starten.',
  } : {
    title: 'Return to identity verification',
    body: 'Return to the app to check the result and confirm your details. This page does not save profile data.',
    waiting: 'Opening the app in a few seconds…',
    link: 'Return to the app now',
    recovery: 'If the app does not open, open it yourself and go to identity verification. You can check the status or start again there.',
  };
  const serializedUrl = JSON.stringify(returnUrl).replace(/</g, '\\u003c');
  const escapedUrl = returnUrl.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
  return `<!doctype html><html lang="${language}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${text.title}</title></head><body><main><h1>${text.title}</h1><p>${text.body}</p><p>${text.waiting}</p><p><a href="${escapedUrl}">${text.link}</a></p><p>${text.recovery}</p></main><script>setTimeout(()=>window.location.assign(${serializedUrl}),5000);</script></body></html>`;
}
