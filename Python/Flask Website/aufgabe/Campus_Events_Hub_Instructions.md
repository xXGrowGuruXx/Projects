# Miniprojekt: Campus-Veranstaltungszentrum

In diesem Projekt entwickeln Sie in einer kleinen Gruppe eine Webanwendung mit **Flask**, **HTML/CSS**, **JavaScript** und **Git**.

## Projektziel

Erstellen Sie eine Webanwendung namens **"Campus Events Hub"**, über die Studierende Veranstaltungen Ihrer Universität einsehen, einreichen und daran teilnehmen können. Kernziel ist es, die Zusammenarbeit mit **Git** in einem realen Gruppenprojekt zu erlernen.

---

## Teamzusammenarbeit & Git-Workflow

Jede Gruppe muss:

- Ein **GitHub-Repository** erstellen und alle Mitglieder einladen.
- Rollen zuweisen (z. B. Frontend, Backend, Git-Manager).
- Für jedes Feature **Branches** verwenden (z. B. „Event-Formular“, „Filter-Feature“, „Datenbankmodelle“).
- **Pull Requests** erstellen und den Code der anderen vor dem Mergen überprüfen.
- Einen übersichtlichen **Commit-Verlauf** mit aussagekräftigen Nachrichten pflegen.

> Tipp: Arbeiten Sie NICHT direkt am Haupt-Branch.

---

## Website Features

### 1. Startseite

- Eine Liste der bevorstehenden Veranstaltungen anzeigen.
- Eine Suchfunktion für die Suche nach Veranstaltungsnamen integrieren.
- Filter nach Kategorie oder Datum hinzufügen (mit JavaScript).

### 2. Veranstaltungsseite

- Formular zur Veranstaltungseinreichung:
  - Veranstaltungsname
  - Beschreibung
  - Datum
  - Ort
  - Kategorie
- Formularvalidierung mit JavaScript (clientseitig) und Flask (serverseitig).
- Speicherung der Veranstaltungen in einer SQLite-Datenbank.

### 3. Veranstaltungsdetailseite

- Ein Klick auf eine Veranstaltung zeigt alle Details an.
- Ein „Gefällt mir“-Button erhöht den Like-Zähler (JS-basierte Interaktion).

### 4. (Optional) Admin-Seite

- Passwortgeschützter Admin-Bereich.
- Alle Termine einsehen und löschen.

---

## Zu verwendende Technologien

- Python & Flask (Backend)
- HTML/CSS (Frontend)
- JavaScript (Interaktion)
- SQLite (Datenbank)
- Git & GitHub (Versionskontrolle & Zusammenarbeit)

---

## Abzugebende Dateien

- GitHub-Repository mit:
  - dem gesamten Quellcode
  - Branches und Pull Requests
  - einer README.md mit:
    - der Projektbeschreibung
    - der Einrichtungsanleitung
    - den Beiträgen der Teammitglieder

- einer funktionierenden Webanwendung (kann lokal getestet werden).
- einer kurzen Präsentation im Unterricht (5–10 Minuten).

---

## Tips

- Kommunizieren Sie regelmäßig in Ihrem Team.
- Führen Sie häufig Commits und Pulls durch.
- Schreiben Sie aussagekräftige Commit-Nachrichten.
- Nutzen Sie Pull Requests, um Code zu überprüfen und zu diskutieren.
- Code Testen vor Merge.

Viel Erfolg!
