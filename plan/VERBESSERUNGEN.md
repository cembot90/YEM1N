# YEM1N: Liste der nächsten Verbesserungen

Stand 01.11.2026. Ergebnis von drei Prüfungen (Store-Regeln für Kinder-Apps, Lernen und Spaß, Gleichstand iOS und Android).
Gilt für beide Apps. Was erledigt ist, wird abgehakt und bleibt stehen. Offene Unterschiede zwischen den Apps stehen
zusätzlich im Android-Repo in `docs/ABGLEICH-IOS.md`.

## Erledigt am 01.11.2026 (auf `entwicklung`, wartet auf Test am Gerät)

- [x] Erwachsenen-Tor vor Einstellungen, Links, Mail und Teilen, auf jedem Gerät (Pflicht für die Kinder-Kategorie).
- [x] Mehrdeutige Aufgaben korrigiert: Großschreiben, I und l, Satzzeichen, Quader, Formen, Porträt, Zählfragen, Generator-Text.
- [x] Android an iOS angeglichen: Sprachen zuerst aus, Englisch immer in der Lernwelt, Tagesziel 2 bis 10.
- [x] Klarere Meldungen bei Pause und Limit des Familien-Dienstes (beide Apps, schon auf `main`).

## Vor der Veröffentlichung (Store)

1. **Gemini Nano auf Android:** Prüfen, ob die Bedingungen für ML Kit GenAI eine Altersgrenze haben. Wenn ja, die KI im
   Store-Build abschalten. Die festen Sätze des Erklär-Freunds reichen. (`speicher/KiText.kt`, `build.gradle.kts`)
2. **Privacy-Manifest iOS:** Nach dem nächsten TestFlight-Upload auf Mails mit "ITMS-91053" achten. Vermutlich fehlt
   `NSPrivacyAccessedAPICategoryFileTimestamp` (Grund `C617.1`) wegen der Gerätestimmen (sherpa-onnx).
3. **Datenschutz und Data Safety:** QR-Scanner (Google Play-Dienste), Firebase-Installations-ID und Zustellmessungen von FCM
   in Datenschutztext, `InfoTexte.kt`, `docs/index.html` und Data Safety nennen. Dienstleister im Auftrag zählen bei Google
   nicht als "Teilen".
4. **Altersfragebogen Apple:** Joker mit Freitext innerhalb der Familie ehrlich angeben (Nachrichten zwischen Nutzern).
5. **GPL-3.0 (espeak-ng in den Gerätestimmen) im App Store:** rechtlich klären lassen, notfalls für iOS eine Stimme ohne GPL-Teile.
6. **KI-Sätze melden:** Beim KI-Satz des Erklär-Freunds einen Knopf "Satz melden" anbieten (über Feedback, hinter dem Tor).
7. **Kinder-Kategorie bei Apple:** Mit dem Tor ist der wichtigste Punkt erledigt. `store/APPSTORE.md` Abschnitt 3 neu entscheiden.

## Lernen (nach Nutzen pro Aufwand)

1. [x] **Zweiter Versuch vor der Lösung** (04.11., beide Apps auf `entwicklung`): Beim ersten Fehler nur ein Hinweis, dann noch ein Versuch, erst dann die Erklärung.
   Die Lobsätze `Lob.nachFehler` gibt es schon. Münzen nur für "gleich richtig".
2. **Fehler aus der Lernwelt ins Fehlerheft:** Bisher filtert das Fehlerheft auf Arbeiten ohne `spezial`, und ein neu
   gestartetes Thema löscht die alten Fehler. Vorsicht beim Datenmodell, Yemins Fortschritt darf nicht verloren gehen.
3. **Schwesteraufgabe im Fehlerheft:** Statt derselben Rechnung eine neue Aufgabe desselben Themas. Dazu `Fehlerplan.noetig = 3`,
   damit der Abstand von 7 Tagen auch erreicht wird.
4. **Schwierigkeit passt sich an:** Generatoren mit Stufen 1 bis 3. Nach drei Sternen eine Stufe höher, unter 50 Prozent tiefer.
5. **Lesen:** Je Runde zwei bis drei Texte mit allen ihren Fragen statt zehn Texte mit je einer Frage. Mehr Lesetexte.
6. **Vorlesen vollständig:** Antwortknöpfe, Einheiten (cm, kg, ct) und große Zahlen mit Leerzeichen vorlesen.
7. **Münzen fair:** Themen unter der eigenen Klasse und Themen mit drei Sternen bringen halbe Münzen.
8. **Aufgabe deutlicher:** Arbeitsanweisung ("Halbiere die Zahl") größer und weiß statt klein und blass.
9. **Tippziele:** Vorlese-Knopf mindestens 44 Punkte groß.
10. **Fehlende Themen Mathe:** Platzhalteraufgaben, Tausch- und Umkehraufgaben, Zahlenfolgen, Symmetrie, Würfelnetze,
    Punkt vor Strich in der Lernwelt, halbschriftliches Teilen, Kalender, Kommazahlen bei Größen, Diagramme.
11. **Fehlende Themen Deutsch:** Selbstlaute und Mitlaute, Nomen auf -ung, -heit, -keit, wörtliche Rede, Lernwörter abschreiben.
12. **Training aus der Lernwelt:** die zwei schwächsten Lernwelt-Themen statt nur der Generator-Vorlagen.
13. **"Heute dran"-Karte:** oben in der Lernwelt eine Empfehlung (Fehlerheft oder nächstes Thema).
14. **Lob für die Anstrengung:** weniger "Du bist ein Star", mehr "Gut gerechnet, erst bis zur 10".
15. **Zahlentastatur:** immer mindestens 4 Stellen erlauben, damit die Länge der Lösung nichts verrät.
16. **Kleine Aufgabenvorräte:** Bildaufbau, Singstimmen und Lesen haben so wenige Aufgaben, dass Runden sich wiederholen.
