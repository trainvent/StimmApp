'use client';

import { useEffect, useState } from 'react';

export default function GroupInvitePage() {
  const [invalidInvite, setInvalidInvite] = useState(false);
  const [isVivot, setIsVivot] = useState(false);

  useEffect(() => {
    const vivotHost = window.location.hostname.toLowerCase().includes('vivot.net');
    const params = new URLSearchParams(window.location.search);
    const groupId = params.get('groupId');
    setIsVivot(vivotHost);

    if (!groupId) {
      setInvalidInvite(true);
      return;
    }

    const destination = new URL(
      '/group-invite',
      vivotHost ? 'https://web.vivot.net' : 'https://web.stimmapp.net',
    );
    destination.searchParams.set('groupId', groupId);
    window.location.replace(destination.toString());
  }, []);

  const brand = isVivot ? 'Vivot' : 'StimmApp';

  return (
    <main className="invite-page">
      <section className="section-card invite-card">
        <img
          className="invite-logo"
          src="/icons/Icon-512.png"
          alt={brand}
        />
        <h1>
          {invalidInvite
            ? (isVivot ? 'Invalid group invitation' : 'Ungültige Gruppeneinladung')
            : (isVivot ? 'Opening group invitation…' : 'Gruppeneinladung wird geöffnet…')}
        </h1>
        <p>
          {invalidInvite
            ? (isVivot
              ? 'This link does not contain a group ID.'
              : 'Dieser Link enthält keine Gruppen-ID.')
            : (isVivot
              ? `If ${brand} is not installed, the invitation will open in the web app.`
              : `Wenn ${brand} nicht installiert ist, wird die Einladung in der Web-App geöffnet.`)}
        </p>
        {invalidInvite && (
          <a className="button" href="/">
            {isVivot ? 'Back to home' : 'Zur Startseite'}
          </a>
        )}
      </section>
    </main>
  );
}
