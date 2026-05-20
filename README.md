# PlanEats (MVP)

App per pianificare i pasti della settimana (Colazione / Pranzo / Cena + **Snack opzionale**) e generare la **lista della spesa** raggruppata per categorie (ortofrutta, carne, pesce, ecc.) con possibilità di **spuntare** gli elementi.

## Cosa include
- **Menu**: selettore Lun–Dom + schede per pasto con *Aggiungi/Modifica*
- **Ricettario**: ricette con ingredienti (categoria + quantità + unità)
- **Spesa**: lista generata dalla settimana corrente, raggruppata per categoria + checkbox persistenti
- **Report / Profilo**: placeholder (pronti per ampliamenti)
- **Salvataggio locale**: dati in un file JSON sul dispositivo (offline, senza login)

## Come eseguirla
1. Installa Flutter sul tuo PC: https://docs.flutter.dev/get-started/install
2. Crea un nuovo progetto Flutter (una volta sola):
   ```bash
   flutter create planeats
   ```
3. Copia il contenuto di questa cartella dentro la cartella del progetto creato (sovrascrivendo `pubspec.yaml` e la cartella `lib/`).
4. Da terminale, nella cartella del progetto:
   ```bash
   flutter pub get
   flutter run
   ```

## Pubblicazione su Play Store (check rapido)
- Cambiare `applicationId` (Android) e nome app
- Icona + screenshot
- Privacy policy (anche se l’app è offline)
- Build:
  ```bash
  flutter build appbundle
  ```

## Prossimi step consigliati
- Selezione porzioni e moltiplicatori quantità
- Filtri (vegetariano, allergeni)
- “Piano settimana” con copie/duplicazioni e template
- Cloud + login (facoltativo)

