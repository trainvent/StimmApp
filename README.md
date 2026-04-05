# StimmApp
eine App die politische Volksentscheide vereinfachen soll. Auf Bundes- und Landesebene.

![photo_2025-11-25_20-06-03](https://github.com/user-attachments/assets/c36ef5fb-a589-49cd-bdec-1a949d799bbc)

## gewünschte Funktionen
- gezielter Umfang: vorest Petitionen, Unfragen. Irgentwann erhofft Volksentscheide, Wahlen.
- Anmeldung per BundID/e-ID: Eine eindeutige Verifizierung sicherstellen.
Dadurch können aussagekräftige Standpunkte entstehen und verlässliche Umfragen stattfinden.
- ermöglicht das Erstellen und Ausfüllen von Petitionen sowie Umfragen
- eventuell auch Landes/-Bundestagswahl Option
- bietet Filterfuntionen für Petitionen und Umfragen
- bietet die Funtkion Kanälen, wie zum Beispiel Peta, den Grünen, jugend Recherchiert etc. zu folgen.

## Regeln für Benutzer
- 1 Petition und Umfrage pro Tag
- Verröffentlichungen können nur solange keiner unterschrieben hat zurückgezogen werden

## Regeln für Entwickler
- autentifizierungsgetriebenes Benutzermanagment

## Lizenz
Dieses Projekt ist unter der **GNU General Public License v3.0** lizenziert.
Siehe `LICENSE`.

## Website Deployment
Die statische Website liegt im Ordner `website` und wird per GitHub Pages aus GitHub Actions veröffentlicht.

### Deployment Workflow
- Workflow: `.github/workflows/deploy-pages.yml`
- Branch: `main`
- Build-Verzeichnis: `website/out`
- GitHub Pages Base Path: `/StimmApp`

### Lokaler Build
```bash
cd website
npm ci
npm run build
PAGES_BASE_PATH=/StimmApp npm run build
```
