# Release notes

## Version 1.0.0 (build 1): first offline POS release

An offline-first restaurant POS for Android, built on the existing thermal-printer app. All data stays on the device in one local database. Nothing needs the internet; LAN printers only need the local network.

### What's included
- **Menu:**
  - categories, items, prices and tax profiles (inclusive or exclusive, CGST/SGST/IGST);
  - variants and add-ons, kitchen stations, favourites, search;
  - CSV import and export.
- **Tables and orders:**
  - areas and tables, dine-in, takeaway and delivery;
  - notes, discounts with reasons, hold and resume;
  - move, merge and split orders.
- **Kitchen tickets (KOT):** routed by station. Only new items print. Void tickets print for items cancelled after sending. Reprints are marked and never create new records.
- **Billing:**
  - inclusive and exclusive tax, service charge, round off;
  - bill numbers with your own prefix;
  - bill preview, print and reprint marked DUPLICATE;
  - void with a reason.
- **Payments:**
  - cash with change, UPI (with a QR code; always marked "staff-confirmed", never "verified"), card, and other methods;
  - split and part payments, dues;
  - reversals with a reason that keep the original entry.
  - Every amount comes from individual ledger entries.
- **Shifts and cash drawer:**
  - opening cash, cash in and out, expenses;
  - closing count by notes and coins, short or over with a reason;
  - shift report.
  - UPI and card are kept out of drawer cash.
- **Reports:**
  - daily or date-range sales, kept apart from money collected;
  - items, categories, staff, tables, tax, discounts, voids, expenses, dues and shifts;
  - a check against the payment ledger on every report;
  - printed summary and CSV export.
- **Staff and permissions:**
  - owner, manager, cashier, waiter and kitchen roles, with permissions you can change;
  - PIN sign-in that works offline, with lock-out and auto-lock;
  - one-time manager approval;
  - an owner recovery code;
  - an activity log.
- **Stock (optional):**
  - ingredients, opening stock, purchases, wastage and counts;
  - recipes for items and for variants and add-ons;
  - stock taken when the KOT is sent or when the bill is made, never twice;
  - low-stock alerts, history and CSV.
- **Backup and restore:**
  - verified backups, optionally protected with a password (AES-256-GCM);
  - restore from the device or from a file, with checks and typed confirmation;
  - an automatic pre-restore backup, and older backups are upgraded.
- **Reliability:**
  - every change is saved in one database transaction, with an audit log;
  - duplicate taps and retries are ignored;
  - a persistent print queue with retry;
  - a local error log, and a clear screen if the data cannot be opened.
- **Printers:** all existing support is kept: Bluetooth, USB and LAN, 58 and 80 mm, text and raster (Hindi, ₹, emoji, logo), diagnostics.

### Before publishing (release blockers)
1. **App ID:** the app is still `com.example.thermalprinter`.
   - Google Play does not accept `com.example.*` IDs.
   - Pick the final ID **before** shops install it. Changing it later makes it a different app, so data would have to be moved with backup and restore.
   - Change `applicationId` and `namespace` in `android/app/build.gradle.kts` and move the Kotlin package folder to match.
2. **Signing key:** release builds use the debug key until `android/key.properties` exists.
   - Create an upload key, for example `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
   - Add `storeFile`, `storePassword`, `keyAlias` and `keyPassword` to `android/key.properties`. Neither file is committed (see `android/.gitignore`).
   - Keep the key and its passwords safe. They are needed for every future update.
3. **Name and icon:** the app is shown as "Thermal POS Printer" with the default Flutter icon. Change `android:label` in `AndroidManifest.xml` and the launcher icons if needed.
4. **Device tests:** run [TEST_CHECKLIST.md](TEST_CHECKLIST.md) on the target devices and printers.
5. **Version:** `version:` in `pubspec.yaml` (now `1.0.0+1`). Increase the build number for every release.

### Building
```
flutter build apk --release
```
The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. For Google Play, use `flutter build appbundle --release`.

### Known limitations
- **UPI and card:** payments are confirmed by staff; the app cannot see the bank.
- **Tax summary:** this is what the app calculated. It is not a GST return; check it with an accountant.
- **Stock:** not valued, with no unit conversion in recipes. Items voided or cancelled after the KOT count as used.
- **Permission checks:** they happen in the screens, except for staff management, which is also checked in the data layer. Everything is logged.
- **PIN security:** PINs are stored as hashes in the database, so a short PIN can be guessed from a copied database or a backup without a password. Use password-protected backups when sharing.
- **Restore:** it finishes when the app is restarted; you close and reopen the app yourself.
- **Reports:** a month of data on a slow phone may take several seconds. On the development PC a report for 400 bills took about 0.4 s.
- **Nothing tested on real devices yet:** no device or printer was connected during development. See the checklist.
