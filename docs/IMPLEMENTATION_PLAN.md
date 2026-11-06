# Offline Restaurant POS — Phase 0 Audit & Implementation Plan

Audit date: 2026-11-06. Scope: Phase 0 only (no behaviour changed).
Source brief: `offline_restaurant_pos_cloud_coding_master_prompt.md`.

> **Repository note:** git was initialised at the start of Phase 1. Commit
> `5786e70` is the untouched baseline as audited.

---

## 1. Current architecture and versions

| Item | Value |
|---|---|
| Flutter / Dart | Flutter 3.47.2 stable (rev d3b14c8769), Dart 3.13.2 (`environment.sdk: ^3.13.2`) |
| Flutter package | `thermalprinter` (version 1.0.0+1) |
| Android applicationId / namespace | `com.example.thermalprinter` (template default — must change before release; changing it later orphans installed data) |
| Android build | AGP 8.7.3, Kotlin plugin 2.1.20 (declared in `android/settings.gradle`), Gradle 9.3.1 wrapper, Java/JVM 17, min/target/compile SDK = Flutter defaults |
| App label | "Thermal POS Printer" |
| Platforms present | Android only (`android/`); no `ios/`, `web/`, `windows/` |
| State management | None (StatefulWidgets + singletons `StorageService`, `PrintQueueManager`) |
| Persistence | `shared_preferences` JSON blobs (Dart) + a **separate** native `SharedPreferences` file `thermal_printer_prefs_v2` (Kotlin) |
| Dependencies | `shared_preferences 2.5.6`, `image 4.10.1`, `qr_flutter 4.1.0`, `intl 0.19.0`, `permission_handler 11.4.0` (declared, **never used**), `google_fonts 6.3.3` (declared, unused), `blue_thermal_printer 1.2.3` (unmaintained since 2021; needs a namespace/manifest patch in `android/build.gradle.kts`) |
| Tests | One smoke widget test (`test/widget_test.dart`) |

Stray files at the project root (`gradlew`, `gradle/`, `gradle.properties`, `gradle/libs.versions.toml` with AGP 9.4.1) look like an Android Studio artifact; the Flutter build uses `android/`. Leave them alone until confirmed unused, then delete in a cleanup change.

### Layering today

```
UI (lib/screens, lib/widgets)
  └─ StorageService (SharedPreferences JSON)  ── PrintQueueManager (in-memory list + JSON mirror)
        └─ SmartPrintEngine (Dart ESC/POS + Flutter raster)
              └─ PrinterAdapter: Bluetooth (blue_thermal_printer) | USB (MethodChannel) | Network (dart:io Socket)

NativeEngineService ─MethodChannel "com.example.thermalprinter/engine"─▶ Kotlin PrinterManager
        └─ BillFormatter / KotFormatter / CalibrationWizard ─▶ Kotlin transports (BT SPP, USB bulk, TCP)
```

There are **two parallel print engines**: the Dart one (used by the queue, test dialog) and the Kotlin one (used only by the Test screen buttons). They do not share formatting, profiles, or settings.

---

## 2. Existing features and printer transports

### What works (by code reading; needs hardware confirmation)

| Feature | Path | Status |
|---|---|---|
| Save/edit/delete printer profiles (BT/USB/LAN, 58/80mm, role) | `lib/screens/add_edit_printer_screen.dart`, `lib/services/storage_service.dart` | Works. Delete has **no confirmation**. |
| Bluetooth via plugin (bonded devices only) | `lib/printers/bluetooth_printer_adapter.dart` | Works if permission already granted. |
| USB via MethodChannel `com.example.thermalprinter/usb` | `lib/printers/usb_printer_adapter.dart`, `MainActivity.kt` | Works after the user re-tries following the permission prompt. |
| LAN TCP 9100 | `lib/printers/network_printer_adapter.dart` | Works; 5 s connect timeout. |
| Persistent print queue (pending/printing/printed/failed), manual retry | `lib/queue/print_queue_manager.dart`, `lib/screens/queue_screen.dart` | Partially (see risks). |
| Print history log (last 200) | `lib/screens/history_screen.dart` | Works; **Reprint is fake** (see below). |
| Print modes Fast / Compatibility / Full-image | `lib/printing/smart_print_engine.dart` | See defects. |
| Native Kotlin bill/KOT/calibration with Android raster (Hindi, emoji) | `android/.../formatters/*.kt`, `engine/ThermalRasterEngine.kt` | Works; the only path with a real KOT layout. |
| Diagnostics report → clipboard | `lib/services/diagnostics_service.dart` | Works. |
| JSON POS integration (in-app sample enqueue) | `lib/services/pos_integration_service.dart`, `settings_screen.dart` | Works for the sample only; no external entry point. |

### Defects found (must be fixed before these paths carry real bills)

| # | Defect | Where | Impact |
|---|---|---|---|
| D1 | Every real queued order prints hard-coded test content: "Special: ✓ ★…", "Emoji: 😊…", "Hindi: नमस्ते…", "Printer Status: OK", order-ID QR | `smart_print_engine.dart` (all three modes) | Customers would get test text on every bill. The Dart engine is a test-page generator, not a bill/KOT formatter. |
| D2 | **Fast Mode always throws**: `latin1.encode()` on `₹` (and the emoji/Hindi lines) raises `ArgumentError` | `escpos_builder.dart` `text()`; `smart_print_engine.dart` | Any job in Fast Mode fails. |
| D3 | **Dart raster is decoded with the wrong channel count**: `img.Image.fromBytes` gets RGBA bytes but defaults to 3 channels | `raster_generator.dart` `imageToEscPosRaster` | Raster text, QR codes and full-image mode print sheared or garbled output. Fix: `numChannels: 4`. |
| D4 | Queue de-duplicates by `orderId` only — a BILL queued while that order's KOT is pending silently returns the KOT job id and is never printed | `print_queue_manager.dart` `addOrderToQueue` | Silent loss of a print job. |
| D5 | Job ids are `JOB-<millis>`; jobs left in `printing` at app kill are never retried or flagged; queue persistence (`saveQueue`) is fire-and-forget, not awaited before bytes are sent | `print_queue_manager.dart` | Collisions; stuck jobs; job may be lost if app dies right after enqueue. |
| D6 | History "Reprint" enqueues `TestReceiptGenerator.buildTestOrder`, not the original job | `history_screen.dart` `_reprint` | Fake reprint. |
| D7 | Native bills print demo defaults: "MYGENIE RESTAURANT", "123 Main Street", GSTIN `27AAAAA0000A1Z5`, FSSAI, customer "Rahul Sharma", status "✓ PAID", payment "UPI" when fields are missing. The receipt template is never editable from Flutter | `ReceiptTemplate.kt`, `PrinterStorageService.kt`, `MainActivity.parseOrder` | Bills with a fake GSTIN and false "PAID" status. |
| D8 | Native profile ignores user settings: Dart always sends `darknessPreset: EXTRA_DARK`, `bitmapThreshold: 150`; printable width is forced to 384/576 | `native_engine_service.dart`, `MainActivity.parseProfile` | Printable width cannot be configured per printer. |
| D9 | USB: `bulkTransfer(... bytes.size ...)` in one call, and any `>= 0` result is treated as success, even a short write; no chunking | `MainActivity.kt`, `UsbPrinterTransport.kt` | Large raster jobs can be truncated yet reported as printed. |
| D10 | USB permission: no `BroadcastReceiver` for the result; `PendingIntent` is `FLAG_IMMUTABLE` with an implicit intent (Android 12+ needs `FLAG_MUTABLE` + `setPackage` for the permission extras; Android 14 rejects mutable implicit intents) | `MainActivity.kt`, `UsbPrinterTransport.kt` | First USB print always fails; the user must retry manually. |
| D11 | No runtime permission requests anywhere (`BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN` on Android 12+); errors are swallowed (`catch (_)`) when listing bonded devices | `add_edit_printer_screen.dart` | Empty Bluetooth list on Android 12+ and no explanation. Manifest also lacks `android:maxSdkVersion="30"` on legacy `BLUETOOTH`/`BLUETOOTH_ADMIN`/location. |
| D12 | Bluetooth adapter is a global singleton (`BlueThermalPrinter.instance`), so only one BT printer can be connected at a time; `isConnected` returns true for *any* connected BT device | `bluetooth_printer_adapter.dart` | A job can go to the wrong BT printer when two are configured. |
| D13 | `getPrinterForRole` silently falls back to the first printer | `storage_service.dart` | KOT may print on the bill printer without notice. |
| D14 | Raster images are sent as one `GS v 0` block of any height, with no banding | both engines | Cheap BT printers with small buffers may drop data on long receipts. |
| D15 | Money is `double` throughout | all models | Rounding drift; unsuitable for a ledger. |

---

## 3. Current storage and data-loss risks

| Store | Keys | Contents |
|---|---|---|
| Flutter `SharedPreferences` (`FlutterSharedPreferences.xml`) | `saved_printers_v1`, `print_queue_v1`, `print_history_v1`, `default_print_mode_v1` (`printer_routing_v1`, `auto_reconnect_v1` are declared but unused) | JSON arrays |
| Native `SharedPreferences` `thermal_printer_prefs_v2` | `saved_printers_list_v2`, `saved_receipt_template_v2` | Written only as a side-effect of native prints; template never written |

Risks:
- Whole-list read-modify-write on every change; no atomicity, no transactions, no schema version.
- Every JSON decode error returns `[]`, so one corrupt value **silently wipes** printers, queue or history on the next save.
- History is capped at 200 records and the oldest are dropped.
- `rawBytes` on `PrintJob` is never serialized.
- No backup/export.
- There is no order, menu, payment or bill data yet, so nothing financial is at risk today. The only user data to preserve is **printer profiles, the print mode, and queue/history**.

---

## 4. Existing screens and missing modules

Screens: `main_navigation_screen.dart` (4 tabs: Printers, Queue, History, Settings), `printers_screen.dart`, `add_edit_printer_screen.dart`, `queue_screen.dart`, `history_screen.dart`, `settings_screen.dart` (print mode, sample-JSON enqueue, links to Test and Diagnostics), `test_screen.dart` (native bill/KOT/calibration/emoji/Hindi tests), `diagnostics_screen.dart`. Widgets: `printer_card.dart`, `status_badge.dart`, `test_print_dialog.dart`. Theme: `core/theme/app_theme.dart` (light only).

Not started at all: dashboard, menu, tables/areas, order taking, KOT routing by station, billing/tax, payments ledger, shifts/cash/expenses, reports, staff/permissions, inventory, backup/restore, business profile settings, local database.

---

## 5. Source paths by module

| Module | Existing files | Planned location (new) |
|---|---|---|
| Printer transports (Dart) | `lib/printers/*.dart` | keep |
| Printer transports (native) | `android/app/src/main/kotlin/com/example/thermalprinter/transports/*.kt`, `MainActivity.kt` (USB channel) | keep; fix D9/D10 in place |
| ESC/POS + raster | `lib/printing/escpos_builder.dart`, `raster_generator.dart`, `hybrid_text_parser.dart`, `core/constants/escpos_commands.dart`; native `engine/*.kt` | keep; fix D2/D3 |
| Receipt layouts | `lib/printing/smart_print_engine.dart` (test layout), native `formatters/BillFormatter.kt`, `KotFormatter.kt` | `lib/printing/layouts/{bill,kot,shift_report,payment_receipt}_layout.dart` that build from real records; keep `SmartPrintEngine` as the test-page path |
| Queue | `lib/queue/print_queue_manager.dart`, `lib/models/print_job.dart` | back by DB tables `print_jobs` / `print_attempts` |
| Storage | `lib/services/storage_service.dart` | `lib/data/db/` (database, tables, migrations), `lib/data/repositories/` |
| Domain logic | none | `lib/domain/` (money, tax calc, bill calc, payment status, order numbering) — pure Dart, unit-tested |
| POS UI | none | `lib/features/{dashboard,menu,tables,orders,billing,payments,shifts,reports,staff,settings,backup}/` |

---

## 6. Proposed schema and migration plan

### Database choice

**Drift (SQLite) + `sqlite3_flutter_libs`**, one database file `pos.db` in the app documents directory.
- Typed tables, compile-time-checked queries, `transaction()`, a `MigrationStrategy` with numbered `schemaVersion`, and `drift_dev` schema dumps for migration tests.
- Runs in-memory on the dev host for unit tests (`NativeDatabase.memory()`). **Verify in Phase 1** that host SQLite is available on Windows for `flutter test`; the fallback is `sqflite` + `sqflite_common_ffi`.
- No second database: `shared_preferences` stays only as a legacy source until the migration completes.

### Conventions
- Primary keys: UUID v4 text (`uuid` package) on every table; human numbers (order no., bill no.) are separate columns.
- Money: **integer paise** (`INTEGER`), never `double`. Tax rates in basis points (5% = 500). Quantities as integer milli-units if fractional quantities are needed (inventory), otherwise integer.
- Time: `created_at` / `updated_at` stored as UTC epoch milliseconds; display in device local time. `business_date` (local `yyyy-MM-dd`) on orders, bills, payments and shifts for day reports and daily numbering.
- Soft-delete via `is_active` / `archived_at` for anything referenced by history; `ON DELETE RESTRICT` on historical foreign keys; `CASCADE` only for pure children of drafts (e.g. a draft line's add-ons).
- Idempotency: `client_request_id` UNIQUE on `payments`, `orders` (creation), `kitchen_tickets`, `print_jobs.source_key`.
- Audit: an `audit_log` row is written in the same transaction as every financial change.

### Entities (columns abbreviated)

- **business_profile** (single row): name, address, phone, gstin?, fssai?, footer, logo_path?, upi_id?, upi_qr_path?, currency='INR'.
- **app_settings**: key/value (typed accessors) — print mode, rounding rule, service charge %, order numbering scheme, stock-deduction event.
- **tax_profiles**: id, name, rate_bp, is_inclusive, split_mode (NONE | CGST_SGST | IGST), active.
- **staff_users**: id, name, role, pin_hash, pin_salt, active. **role_permissions**: role, permission (Phase 9).
- **dining_areas**: id, name, sort, active. **restaurant_tables**: id, area_id, label, seats, sort, active.
- **menus**, **categories** (parent_id for subcategories), **menu_items** (category_id, name, description, image_path, sku, base_price_paise, tax_profile_id, food_type, active, dine_in, takeaway, station_id, sort, prep_minutes, is_favorite).
- **variant_groups** / **variant_options**, **addon_groups** / **addon_options**, **item_option_groups** (item_id, group_id, kind, required, min, max, sort).
- **printer_profiles**: id (kept from legacy), name, connection_type, mac, vendor_id, product_id, device_name, ip, port, paper_width, printable_dots, chars_per_line, role, darkness, threshold, dithering, cut_mode, feed_lines, print_mode, active, last_ok_at, last_error.
- **printer_stations**: id, name (Kitchen/Bar/…); **station_printers**: station_id, printer_id, is_fallback.
- **orders**: id, order_no, business_date, type, table_id?, customer_name?, customer_phone?, guests?, staff_id?, status (DRAFT | RUNNING | BILLED | SETTLED | CANCELLED), notes, cancel_reason, client_request_id, created/updated.
- **order_lines**: id, order_id, menu_item_id (nullable ref), **snapshot** name / variant text / unit_price_paise / tax_rate_bp / is_inclusive / station_id, qty, sent_qty, voided_qty, notes, line_discount_paise, status.
- **order_line_addons**: line_id, addon_option_id?, snapshot name, price_paise.
- **kitchen_tickets**: id, order_id, station_id, round_no, kind (NEW | ADD | VOID), client_request_id; **kitchen_ticket_lines**: ticket_id, line_id, qty, snapshot text.
- **bills**: id, bill_no, order_id, status (FINALIZED | VOIDED), subtotal, discount, taxable, cgst, sgst, igst, service_charge, round_off, grand_total (all paise), finalized_at, voided_reason. Payment status is **derived**, not stored as truth.
- **payments**: id, bill_id, order_id, amount_paise, method (CASH | UPI | CARD | OTHER), reference?, tendered_paise?, change_paise?, staff_id, shift_id, status (POSTED), verification ('STAFF_CONFIRMED' for UPI), client_request_id UNIQUE, created_at. Immutable.
- **payment_reversals**: id, payment_id, amount_paise, reason, staff_id, created_at.
- **cash_shifts**: id, opened_by, opening_cash, opened_at, closed_by?, counted_cash?, expected_cash?, variance?, variance_reason?, closed_at?.
- **cash_movements**: id, shift_id, kind (SALE | REFUND | EXPENSE | ADD | WITHDRAW), amount_paise, ref_id, note.
- **expenses**: id, category, amount_paise, note, source (CASH_DRAWER | UPI | BANK | OTHER), shift_id?, created_at.
- **print_jobs**: id, source_type (KOT | BILL | RECEIPT | SHIFT | TEST | LEGACY), source_id, source_key UNIQUE, printer_id, payload_json, status (PENDING | PRINTING | PRINTED | FAILED | CANCELLED), attempts, last_error, created/updated. **print_attempts**: id, job_id, started_at, finished_at, ok, error.
- **audit_log**: id, at, staff_id?, action, entity, entity_id, before_json?, after_json?.
- **inventory_items**, **stock_movements**, **recipes** — Phase 10.
- Drift's own `schemaVersion` plus a **migration_log** table: version, applied_at, notes.

### Migration of existing data (schema v1, Phase 1)

1. On first launch with the database, inside one transaction: read `saved_printers_v1`, `default_print_mode_v1`, `print_queue_v1` and `print_history_v1` from `SharedPreferences`.
2. Insert printers into `printer_profiles`, **keeping their existing `id`s**, with defaults for the new columns (dots/chars derived from paper width, threshold 150, darkness EXTRA_DARK, which matches current native behaviour).
3. Import queue jobs into `print_jobs` as `source_type=LEGACY`. Any job in `printing` becomes `FAILED` with the error "interrupted — verify before retry", because it may already have printed. History rows become `print_attempts` on a synthetic legacy job.
4. Write `migration_log(1, 'imported legacy prefs')` and set the pref `legacy_migrated_v1=true`. **Do not delete the legacy keys** (they stay as a fallback for one release).
5. If decoding fails, abort the import, keep the legacy prefs untouched, show an error banner, and do not mark the import done.
6. Native `thermal_printer_prefs_v2` is not imported (it only mirrors Dart profiles plus the demo template); the native engine will receive the full profile and template from Dart instead.

The Dart model classes (`PrinterDevice`, `PrintJob`) remain the UI-facing types, and repositories map to and from DB rows. This keeps the existing screens working unchanged through Phase 1.

---

## 7. Phased plan — dependencies and risks

| Phase | Depends on | Deliverables | Key risks |
|---|---|---|---|
| **0 Audit** (this document) | — | this file | — |
| **1 Foundation** | git baseline | Drift DB v1, migration_log, legacy-prefs import, `PrinterRepository` + `PrintJobRepository` behind the existing `StorageService` API, business profile & settings tables + screen, money/ID/time utilities, a manual DB file backup (copy + share). **Also fix D3, D4, D5 and D13** (small, isolated, queue-safety-critical) with tests. | Host SQLite for tests; migration must never lose printers — covered by tests on fixture prefs. |
| **2 Menu** | 1 | categories/items/variants/add-ons CRUD, search, sort, deactivate, favorites; CSV import/export with preview + rollback after CRUD is stable | Option-group validation rules |
| **3 Tables & orders** | 2 | areas/tables, dine-in/takeaway, order screen (tablet split view), snapshots, notes, discounts (permission stub), hold/resume, move/merge, daily order numbering | Touch performance on low-end devices; preventing two active orders per table |
| **4 KOT** | 3, printer fixes D1/D2/D7/D8/D11/D12 | station routing + fallback, NEW/ADD/VOID tickets from `sent_qty` deltas, a real KOT layout, queue integration with `source_key` idempotency, retry UI | Duplicate KOTs on retry — mitigated by unique `source_key` and a "may have printed" state |
| **5 Billing & tax** | 3 | pure-Dart bill calculator (inclusive/exclusive, CGST/SGST split, service charge, configurable rounding), finalize → immutable bill, void with audit, real 58/80mm bill layout | Inclusive-tax rounding; must be unit-tested against worked examples |
| **6 Payments** | 5 | ledger, split/partial/advance, cash change, UPI "Record UPI payment" (staff-confirmed only), reversals, payment receipt | Double-tap posting → `client_request_id` UNIQUE + disabled button + transaction |
| **7 Shifts & expenses** | 6 | open/close shift, cash movements, expected vs counted, variance reason, shift report print | Keeping UPI out of the drawer total |
| **8 Reports** | 6, 7 | daily/range/payment/item/category/staff/tax/discount/void/dues/expense reports; CSV export; reconciliation tests (collections = Σ ledger) | Query performance → indexes on business_date, status |
| **9 Staff & permissions** | 3 (stubs used from 3 onward) | PIN login (PBKDF2 via `cryptography`, salt per user, pepper in `flutter_secure_storage`), role permissions, audit viewer | Lockout and recovery for the owner PIN |
| **10 Inventory** (optional) | 6 | items, units, stock-in, wastage, recipes, deduction on a configured event, keyed by order line to prevent double deduction | Scope creep |
| **11 Hardening** | all | migration tests per version, backup/restore with integrity check and pre-restore backup, crash logging (local), release signing, new applicationId, test checklist | applicationId change must happen **before** any production install |

Printer-engine items (D1, D2, D6–D12, D14) are scheduled with Phase 4 because that is when real bill and KOT payloads exist. D3/D4/D5/D13 go into Phase 1 because they affect queue integrity now.

Cross-cutting decisions:
- The **Dart engine becomes the single layout path** for bill and KOT, using the fixed Flutter raster for Hindi/emoji. The native Kotlin formatters remain available (calibration sheet, fallback) but receive the real template and profile. Choosing between them per printer is a profile setting. Neither is removed until the replacement is verified on hardware.
- `PRINTED` means "the transport reported a complete write". The UI states that this does not prove paper came out.
- Navigation becomes a `NavigationRail` (tablet) / `NavigationBar` (phone) with POS, Orders, Tables, Menu, Reports, Settings; the existing printer, queue and history screens move under Settings → Printers.

---

## 8. Baseline verification commands

Run from the project root:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Baseline results (2026-11-06):
- `flutter analyze`: **0 errors, 0 warnings, 14 infos** (deprecated `value`/`groupValue`/`withOpacity`, one unnecessary import).
- `flutter test`: **1/1 passed** (smoke test).
- `dart format --set-exit-if-changed`: **31 of 35 files** would be reformatted. Do this as a standalone formatting-only commit right after the git baseline, so it does not hide real diffs later.
- `flutter build apk --debug`: **FAILS (build blocker).** Flutter 3.47.2 requires AGP ≥ 8.11.1, but `android/settings.gradle` pins `com.android.application` **8.7.3**. The `build/app/outputs/apk/debug/app-debug.apk` in the tree dates from 2025-10-07 and was built with an older toolchain. Proposed fix (first step of Phase 1, or earlier if approved): raise AGP to 8.11.x in `android/settings.gradle`, keep `android.newDsl=false`, confirm Gradle 9.3.1 and Kotlin 2.1.20 compatibility, check that the `blue_thermal_printer` namespace patch in `android/build.gradle.kts` still applies, then rebuild. The app module's `plugins {}` block does not apply `org.jetbrains.kotlin.android` even though it uses a `kotlin {}` block; verify this during the same fix.

---

## 9. Phase checklist

- [x] Phase 0 — audit and plan (this document)
- [x] Phase 1 — git baseline; format-only commit; AGP build-blocker fix; Drift DB v1 + legacy import; repositories; business profile/settings; DB backup; fixes D3/D4/D5/D13; tests (see §10)
- [x] Phase 2 — Menu (see §11)
- [x] Phase 3 — Tables & orders (see §12)
- [x] Phase 4 — KOT + printer fixes D1, D2, D6–D12, D14 (see §13)
- [x] Phase 5 — Billing & tax (see §14)
- [x] Phase 6 — Payments (see §15)
- [ ] Phase 7 — Shifts & expenses
- [ ] Phase 8 — Reports
- [ ] Phase 9 — Staff & permissions
- [ ] Phase 10 — Inventory (optional)
- [ ] Phase 11 — Hardening & release

Manual hardware tests are still required for every transport (BT, USB, LAN) at 58 and 80mm. None have been run as part of this audit.

---

## 10. Phase 1 completion report (2026-11-06)

### Commits
1. `Baseline` — the project as audited, plus this document and Flutter `.gitignore` entries.
2. `Format` — `dart format lib test`, no logic changes.
3. `Build` — AGP 8.7.3 → **8.11.1**, Kotlin 2.1.20 → **2.2.20** in `android/settings.gradle`. These are the minimum versions Flutter 3.47.2 accepts. Flutter warns that support for both will be dropped soon; move to AGP ≥ 9.0.1 / Kotlin ≥ 2.3.20 in a separate change once the `blue_thermal_printer` namespace patch (which uses the legacy `BaseExtension` API) has been checked against AGP 9.
4. `Phase 1` — everything below.

### Features implemented
- **Local database** (Drift on SQLite, `pos.db` in the app documents folder), schema **v1**: `migration_log`, `app_settings`, `business_profiles`, `printer_profiles`, `print_jobs`, `print_history`, `audit_log`. Foreign keys are switched on at open. The schema snapshot is saved in `drift_schemas/pos/drift_schema_v1.json`, so later versions can generate migration tests with `dart run drift_dev make-migrations`.
- **Legacy import** (`lib/data/legacy/legacy_prefs_importer.dart`): copies printers, print mode, queue and history from `SharedPreferences` in one transaction, keeping printer ids.
  - A job left in `printing` becomes `failed` with "may already have printed".
  - Colliding legacy ids are re-issued.
  - Malformed JSON aborts the whole import. Nothing is written, a banner explains what happened, and the import is retried on the next launch.
  - Legacy keys are never modified.
  - Completion is recorded in `app_settings.legacy_prefs_import_v1` and in `audit_log`, not in `migration_log`, which is reserved for schema versions.
- **Repositories** (`lib/data/repositories/`): printers, print jobs/history, settings, business profile, audit. `StorageService` keeps its old method names, so the existing screens did not change.
- **Audit log**: printer create/update/delete, setting changes, business-profile changes, history clears, backups and the legacy import are written in the same transaction as the change.
- **Business profile screen** (Settings → Business Profile): name (required), address, phone, GSTIN, FSSAI, UPI ID and footer, with format validation. Fields start **empty**, never with demo data. Bill and KOT layouts do not read it yet (Phase 4/5), and the screen says so.
- **Backup** (Settings → Backup): `VACUUM INTO` makes a consistent copy. Each backup is re-opened read-only, checked with `PRAGMA integrity_check`, and its schema version is checked. Backups are listed with their verification status and can be shared with the Android share sheet. Location: `Android/data/com.example.thermalprinter/files/backups/`. **Restore is not implemented yet** (Phase 11), and the screen says so.
- **Fallback printer** (Settings): an explicit choice of printer to use when a job's role has no printer, or "None".
- **Delete-printer confirmation dialog.**
- `lib/core/util/`: `Money` (integer paise, strict parsing, Indian grouping `₹1,23,456.78`), `newId()` (UUID v4), `Clock` (UTC epoch-ms storage, local display).

### Defects fixed
| # | Fix |
|---|---|
| D3 | `RasterGenerator.rgbaToEscPosRaster` passes `numChannels: 4`. Transparent pixels are treated as paper; previously a QR code's transparent background printed as a solid black block. |
| D4 | Queue de-duplication is per document (`printType:orderId`), so a BILL and a KOT for the same order are both queued. |
| D5 | UUID job ids. Each job is stored, and marked `printing`, *before* bytes are sent (writes are awaited). Jobs found in `printing` at start-up are failed, not resent. Jobs with no payload fail instead of getting stuck. The recursive `processNext` is now a loop. |
| D13 | No silent fallback to the first printer. A role with no printer uses the configured fallback printer, otherwise the job fails with a clear message. For existing users the import sets the fallback to their first printer, which preserves the old behaviour but makes it visible and changeable. |
| new | The theme loaded the Inter font through `google_fonts`, which **downloads fonts from fonts.gstatic.com at run time**. Offline this logged errors and fell back to Roboto anyway. The theme now uses the platform font and the dependency is removed. Bundle a font asset if a custom typeface is wanted. |

### Dependencies
- Added: `drift`, `sqlite3` (bundles native SQLite for each ABI through build hooks), `path_provider`, `path`, `uuid`, `share_plus`; dev: `drift_dev`, `build_runner`.
- Removed: `google_fonts`.
- `permission_handler` is still declared and unused; it is wired up in Phase 4 (D11).
- After changing tables, run `dart run build_runner build --delete-conflicting-outputs`. `app_database.g.dart` is committed.

### Tests and commands (all from the project root)
| Command | Result |
|---|---|
| `dart format lib test` | clean |
| `flutter analyze` | 0 errors, 0 warnings, 14 infos (unchanged from baseline; all pre-existing deprecations) |
| `flutter test` | **38/38 passed**: money (4), database (3), legacy import (8), printer repository/role routing (4), print queue (11), raster encoding (4), backup (3), app smoke test (1) |
| `flutter build apk --debug` | builds; `libsqlite3.so` present for arm64-v8a, armeabi-v7a and x86_64 |

### Not verified / manual tests still required
- **No Android device was attached**, so the app was not launched. On a device:
  1. Install the *previous* build, add printers and queue a job.
  2. Install this build over it, and check that the printers, print mode and history are still there and the fallback printer is set to the first printer.
  3. Create a backup and share it.
  4. Restart with a job pending.
- Printer hardware was not used. D3 is covered by unit tests on the byte encoding; print a raster test page on a real 58mm and 80mm printer to confirm.

### Known limitations carried forward
- D1, D2, D6–D12 and D14 remain (Phase 4). In particular, queued prints still contain test content, and Fast Mode still fails on `₹`.
- Restore from backup is not implemented yet.
- The `SharedPreferences` legacy keys remain on the device (read-only fallback). Delete them in a later release once the import has been confirmed in the field.

---

## 11. Phase 2 completion report (2026-11-06)

### Commits
- `Phase 2a` — schema v2, domain rules and the menu repository (with tests).
- `Phase 2b` — menu screens, CSV import/export, widget tests and this report.

### Database migration v1 → v2
- New tables: `tax_profiles`, `kitchen_stations`, `menu_categories`, `menu_items`, `option_groups`, `option_choices`, `item_option_groups`, plus indexes on category, SKU and choice group.
- The migration uses Drift's generated `stepByStep` (`lib/data/db/app_database.steps.dart`) and only creates tables, so existing data is untouched. `migration_log` gets a row for v2.
- Schema snapshots are in `drift_schemas/pos/drift_schema_v1.json` and `…_v2.json`. `test/drift/pos/migration_test.dart` checks that v1 → v2 produces exactly the v2 schema, and that existing printers, jobs and settings survive the upgrade.
- Workflow for future schema changes:
  1. Edit `tables.dart` and bump `schemaVersion`.
  2. Run `dart run build_runner build --delete-conflicting-outputs`.
  3. Run `dart run drift_dev make-migrations`.
  4. Write the `fromNToN+1` step.
  5. Run `flutter test test/drift`.

### Data rules
- **No hard deletes anywhere in the menu.** Categories, items, option groups, choices, taxes and stations are switched off instead. A turned-off category also makes its items (and its subcategories' items) not orderable (`MenuSnapshot.isOrderable`).
- Foreign keys are `RESTRICT`, so an item cannot point at a missing category, tax, station or group.
- Validation lives in `MenuRepository` and is shown to staff as-is:
  - Names are required.
  - SKUs must be unique (case-insensitive).
  - Two active items in one category can't share a name.
  - Turning an item back on re-checks for duplicate names.
  - Categories allow one level of subcategories.
  - Option groups need max ≥ 1 and max ≥ min. Choice names must be unique within a group.
  - Tax rates must be between 0% and 100%.
  - A tax can't be turned off while active items use it.
- Money is stored in integer paise and tax rates in basis points (5% = 500). No tax rate is built in, and none is created automatically. The Taxes screen tells the business to confirm its rates with an accountant.
- Every create, update, on/off change, reorder, CSV import and CSV export writes an audit row.

### Ordering logic ready for Phase 3 (`lib/domain/menu/item_configuration.dart`)
- `validateSelection` enforces each attached, active group's min/max, rejects inactive or unknown choices, and returns staff-readable messages.
- `configureItem` returns a `ConfiguredItem` snapshot for an order line. It holds the item name, chosen options (in group order) with their prices, the unit price (base + options), the variant text for the KOT, the tax rate, inclusive flag and split mode, and the station. Order lines will store this copy, so later menu edits cannot change a past bill.

### Screens (new **Menu** tab, first in the bottom bar)
- **Menu list:**
  - Instant search by name or short code.
  - Chips for All, Favourites, each category, and subcategories.
  - Optionally show turned-off items.
  - Headings per category, veg/non-veg/egg marks, a favourite star, and badges such as Off, Category hidden, No dine-in and No takeaway.
  - Drag to reorder when one category with no subcategories is selected.
  - Live refresh through Drift table watches.
- **Item editor:**
  - Name, price, SKU, category (including subcategories), tax, food type, dine-in and takeaway availability, favourite, and on/off.
  - Station, preparation time and description.
  - Attach, detach and reorder variant/add-on groups.
- **Categories:** add, rename, move under a parent, add subcategories, on/off, drag to reorder.
- **Variants & add-ons:** groups with kind, min and max, plus a warning when the minimum can't be met. Choices have an extra price, on/off and drag order.
- **Taxes:** name, rate %, inclusive or exclusive, and how the bill shows it (single line, CGST + SGST, or IGST).
- **Kitchen stations:** add, rename, on/off. Printer routing per station comes in Phase 4.

### CSV (`lib/services/menu_csv_service.dart`, Menu ⋮ → Import / Export CSV)
- **Export:** all items, including turned-off ones, with an `id` column for round-trips. UTF-8 with BOM so Excel shows ₹ and Hindi. Shared through the Android share sheet.
- **Import flow:**
  1. Pick a file.
  2. Preview, with errors listed first, per-line messages, new/update/unchanged counts, and the categories that will be created.
  3. Confirm.
  4. The import runs in **one transaction**, so all rows are saved or none.
- **Matching:** a row matches an existing item by `id`, then `sku`, then category + name.
- **Updates:** a blank cell keeps the current value.
- **Categories:** missing ones are created.
- **Tax and station names must already exist**, so a typo can't silently change billing.
- **Detected in the file:** duplicate SKUs, and duplicate name + category.
- **Separators:** `;` (common in Excel) is detected automatically.
- **Any error blocks the import.**
- Variants and add-ons are not in the CSV.

### Dependencies
- Added `csv` 8.0.0 (parsing and encoding, delimiter auto-detection) and `file_picker` 13.3.2 (Android system file picker; no storage permission needed).

### Tests and commands
| Command | Result |
|---|---|
| `dart format --set-exit-if-changed lib test` | 0 files changed |
| `flutter analyze` | 14 infos, same as baseline; no new issues (the new screens use `onReorderItem`, not the deprecated `onReorder`) |
| `flutter test` | **79/79 passed**. New: migration (3), item configuration (13), menu repository (15), CSV (9), menu screen widgets (2). |
| `flutter build apk --debug` | builds |

### Not done / limitations
- **Not run on a device:** no Android device or emulator was connected. Check by hand:
  - the system file picker for CSV import;
  - the share sheet for CSV export;
  - drag-reorder on a touch screen;
  - the v1 → v2 upgrade on a phone that has Phase 1 data.
- **Deferred:** item photos. The `image_path` column exists; picking and storing a local image needs `image_picker` and is left for later.
- **Deferred:** separate "menus" (e.g. breakfast vs dinner menus). There is one menu, organised by category and subcategory.
- **Deferred:** Excel `.xlsx` import (CSV only; Excel can save as "CSV UTF-8").
- **Deferred:** menu-only backup/restore. The full database backup from Phase 1 already includes the menu; restore is Phase 11.
- **Permissions:** there are no staff permissions yet (Phase 9), so anyone can edit the menu.
- **Phase 3 rule to add:** once orders exist, check that a turned-off item's past orders still show it. The snapshot design covers this. (Done in Phase 3: order lines keep their own copy; see the "menu edits after ordering" test.)

---

## 12. Phase 3 completion report (2026-11-06)

### Commits
- `Phase 3a` — schema v3, order rules, table and order repositories (with tests).
- `Phase 3b` — navigation, tables, order-taking and orders screens, widget tests and this report.

### Database migration v2 → v3
- New tables: `dining_areas`, `restaurant_tables`, `orders`, `order_lines`, `order_line_options`, plus indexes. Only tables are created, so existing data is untouched. Migration tests now cover v1 → v3 with data.
- **Order numbers:** `orders.order_no` restarts at 1 every business day. A unique index on (business_date, order_no) stops two orders getting the same number.
- **Double taps:** `orders.client_request_id` is unique, so creating the same order twice returns the first one.
- **Line snapshots:** each order line stores its own copy of the item name, variant text, base and unit price (paise), tax profile, rate, inclusive flag and split mode, and station. `order_line_options` stores each chosen option's group, name and price. Editing the menu later never changes an existing order.
- **Kitchen tracking:** `sent_qty` and `voided_qty` exist now so the KOT module can track what went to the kitchen. In Phase 3 nothing sets them yet.

### Order rules (`OrderRepository`, all transactional and audited)
- **Starting an order:**
  - Dine-in needs an active table. Takeaway and delivery have no table.
  - **One running order per table.** A second order on a busy table needs an explicit "Start another order" choice. Without it the app offers to open the existing order.
- **Adding items:** adding the same item with the same options, price and instructions increases the existing line's quantity instead of adding a new line.
- **Quantity:** 1 to 999.
- **Items already sent to the kitchen:**
  - Their quantity can't go below the sent amount.
  - They can't be removed and their instructions can't be changed; they must be voided, which comes with KOT in Phase 4.
  - An order with such items can't be cancelled.
- **Cancel:** needs a reason. The lines are kept on record and the table is freed.
- **Discount:** whole-order, percent or ₹ amount, with a required reason. Percent rounds half up to the paisa. The discount never exceeds the items total.
- **Other actions:**
  - Hold and resume.
  - Move to another table; a busy target needs explicit sharing.
  - Merge into another running order: lines move along with their kitchen progress, and the source is closed with the reason "Merged into order #N". This is blocked if the source has a discount.
  - Split chosen whole lines into a new takeaway or dine-in order.
- **Timeline:** every change writes an audit row (entity `orders`). The order's timeline screen reads from these.
- **Business day start** (Settings): choose midnight to 6 am. Orders before that hour count towards the previous day.
- **Totals while ordering:** the screen shows the items total, discount and "Amount before tax", labelled "Taxes and charges are added when the bill is generated". Tax, service charge and rounding are Phase 5.

### Screens
- **Navigation:** tabs are now **Tables, Orders, Menu, Settings**: a bottom bar on phones, a side rail on screens 840 px or wider. Printers, Print queue and Print history moved into Settings, unchanged.
- **Tables:**
  - Area filter with a busy/total count.
  - Table cards show Available / Running / On hold / *n* orders, the order number, the running amount, elapsed time and guests/seats.
  - Tapping a free table starts a dine-in order. Tapping a busy table opens its order, or offers a choice when it has several.
  - A Takeaway button.
- **Manage areas & tables:**
  - Add, rename and switch off areas.
  - Add, edit, move and switch off tables, and add a run of tables at once (e.g. T1–T10).
  - A table or area with a running order can't be switched off.
- **Order screen:**
  - **Menu side:**
    - Search; Enter adds the item whose short code matches, so keyboards and barcode scanners can add items.
    - Quick (favourites) / All / category chips.
    - Item buttons with veg marks.
    - Items not offered for the order type are hidden.
    - Long-press any item to add instructions or a quantity.
  - **Options sheet:** single- and multi-select groups with live rule messages and price. Add is disabled until the choices are valid. One-tap instructions (Less spicy, No onion, Jain…) plus free text.
  - **Order side:**
    - Lines with variant, add-ons, highlighted instructions and a quantity stepper.
    - Tap a line to edit it or remove it.
    - Customer, phone, guests and order note.
    - Discount and Hold buttons.
    - ⋮ menu: move table, merge, split, timeline, cancel (with reason).
  - **Layout:** side by side on tablets; Menu / Order tabs with a running-total bar on phones.
  - **Read-only:** cancelled orders show a banner and their timeline.
- **Orders:** running orders filtered by All / Dine-in / Takeaway / On hold, with buttons to start a dine-in or takeaway order, and today's closed (cancelled) orders.

### Tests and commands
| Command | Result |
|---|---|
| `dart format --set-exit-if-changed lib test` | 0 files changed |
| `flutter analyze` | 14 infos, same as baseline; no new issues |
| `flutter test` | **113/113 passed**. New: order totals and business date (7), order repository (19), table repository (3), order flow widgets (3); migration tests extended to v3. |
| `flutter build apk --debug` | builds |

### Not done / limitations
- **Not run on a device:** no Android device or emulator was connected. Check by hand on a phone and a tablet:
  - touch sizes, the phone tab layout and the tablet split layout;
  - a hardware keyboard or barcode scanner typing a short code and Enter;
  - the v2 → v3 upgrade with Phase 2 data.
- **Not built yet (next phases):**
  - **Send to kitchen, KOT reprint, void items (Phase 4).** No KOT button is shown yet; there are no placeholder buttons.
  - Generate bill (Phase 5).
  - Payments (Phase 6).
  - The "Bill requested" and "Payment pending" table states come with billing.
- **Discounts:** order-level only. Item-level discounts are left for Phase 5, where the bill calculation spreads the discount across tax rates.
- **Split:** moves whole lines only; splitting one line's quantity is not supported.
- **Staff and permissions (Phase 9):** discounts and cancellations require a reason but no permission check yet. `staff_id` / `staff_name` columns exist on orders and are empty until then.
- **Delivery:** the order type exists in the data model, but there is no delivery button or address field.
- **Reservations** are not implemented (optional in the brief).

---

## 13. Phase 4 completion report (2026-11-06)

### Commits
- `Phase 4a` — schema v4, kitchen ticket service, new print engine and layouts, queue fixes (with tests).
- `Phase 4b` — native (Kotlin) and transport fixes, Bluetooth permissions, the KOT screens, routing and printer settings, and this report.

### Database migration v3 → v4
- `printer_profiles` gains nullable `printable_dots`, `chars_per_line`, `raster_threshold` and `feed_lines`, plus `auto_cut` (default on). Existing printers keep the defaults for their paper width.
- New tables:
  - `station_printers`: station → printers. `__default__` covers items without a station.
  - `kitchen_tickets`: order, station (name copied), round number, kind send/void, reason, client request id.
  - `kitchen_ticket_lines`: the printed text copied at send time.
- `test/drift/pos/migration_test.dart` now checks v1 → v4 with data, including the new printer columns.

### Kitchen tickets (`KitchenRepository`)
- **Send to kitchen:**
  - In one transaction it takes every unit not yet sent (`qty − sent_qty`), groups them by station, and writes one ticket per station for this round.
  - It raises `sent_qty` and writes one print job per assigned printer.
  - A repeated tap with the same request id returns the first result; a later tap with nothing new says "Nothing new to send".
- **Adding after a KOT:** increasing a sent line's quantity or adding a new item prints only the extra units in the next round, never the whole order again.
- **Void:**
  - Only units already in the kitchen can be voided (`voided ≤ sent ≤ qty`). Unsent units are simply removed or reduced.
  - It needs a reason. It prints a **VOID / CANCEL** ticket for that station and stops charging those units; the line stays on record.
  - An order can be cancelled only once nothing is left in the kitchen.
- **Reprint:** rebuilds the ticket from its stored copy and prints it with a **\*\*\* REPRINT \*\*\*** banner. It creates no new ticket, changes no quantities, and is audited.
- **Routing:**
  1. The station's own printers.
  2. Otherwise the "Default kitchen" printers.
  3. Otherwise one job routed by role: KOT or Kitchen printer, then the fallback printer, else a clear failure in the queue.
  - Stations without a printer are named in the send confirmation.
- **Failures:** a printer failure never rolls back the order or ticket. The job stays failed with its error, the ticket shows "Print failed" with Retry, and nothing is retried automatically. An interrupted job is still marked "may already have printed" on restart (Phase 1 rule).

### Printer defects fixed
| # | Fix |
|---|---|
| D1 | `SmartPrintEngine` now renders a `ReceiptDocument` from `ReceiptLayouts`: a real **KOT**; a **bill** that prints only the fields provided; and a **printer test page**, used only for "PRINTER_TEST" jobs and labelled as such. Real prints no longer include sample lines. |
| D2 | All ESC/POS text goes through `toPrinterAscii`, which never throws. `₹` becomes `Rs.`, quotes and dashes are normalised, and unsupported glyphs become `?`. Compatibility mode rasters only lines that need it (Hindi, emoji, ₹); Full-image mode rasters the whole receipt. Raster lines use a monospace font sized to the printer's characters per line, so columns line up. |
| D6 | History **Reprint** reprints the original job's stored content, marked REPRINT. If the job was cleared, it says so instead of printing a test page. |
| D7 | Native `ReceiptTemplate`, `PosOrder` and `parseOrder` have no demo values (MYGENIE name, address, GSTIN `27AAAAA0000A1Z5`, FSSAI, "Rahul Sharma", "✓ PAID", "UPI", default IP). Dart sends the business profile as the template, and the native bill skips empty title, payment, status and footer. The Dart `PosOrder` defaults are empty too. |
| D8 | Native prints receive the printer's real width, characters per line and threshold. |
| D9 | USB writes go in 16 KB chunks, and each chunk must be fully accepted. A short or zero write is reported as a failure with the byte count. |
| D10 | The USB permission `PendingIntent` is explicit (package set) and `FLAG_MUTABLE` on Android 12+, which the system needs to attach the result. The message tells staff to tap Allow and retry. |
| D11 | Bluetooth asks for `BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN` ("Nearby devices") at run time before listing or connecting, and shows a clear message if refused or blocked. The manifest limits the legacy Bluetooth and location permissions to Android 11 and older. The paired-device dropdown no longer crashes when a saved printer isn't currently paired. |
| D12 | The Bluetooth adapter remembers which MAC the shared plugin connection belongs to, and disconnects first when a job is for a different printer. |
| D14 | Raster output (Dart and Kotlin) is sent as 128-row `GS v 0` bands. |
| also | Print jobs carry a **source key**, so only one active job exists per document. Jobs have a **Cancelled** state: removing a pending or failed job cancels it (kept until Clear). "KOT" and "Kitchen" printer roles both take kitchen tickets. |

### Screens
- **Order screen:**
  - **Send to kitchen (*n* new)** button.
  - Each line shows "*n* in kitchen, *m* new", "not sent" or "*n* voided"; fully voided lines are struck through.
  - The line sheet has **Void sent**, with quantity, reason chips and free text.
  - ⋮ → **Kitchen tickets** lists every round and void with its print status (Printed / Printing / Print failed with the error), plus **Retry print** and **Reprint**. It also notes that "Printed" means the printer accepted the data.
  - The timeline shows sends, voids and reprints.
- **Menu › Kitchen stations:** a "Default kitchen" row plus one per station, each with **Choose printers** (multi-select) and a summary of where it prints.
- **Settings › Printers › Edit › Print settings (advanced):** printable width (dots), characters per line, image darkness threshold, blank lines before cut, and cut on/off. Empty means the paper-width default.

### Tests and commands
| Command | Result |
|---|---|
| `dart format --set-exit-if-changed lib test` | 0 files changed |
| `flutter analyze` | 13 infos (one fewer than baseline); no warnings or errors |
| `flutter test` | **134/134 passed**. New: kitchen service (7: routing, rounds, idempotency, void, reprint, no-printer fallback, failure with no rollback then retry); receipts (11: wrapping, columns, ASCII safety, KOT/void/reprint/bill content, feed and cut, raster in compatibility mode, banding); send-to-kitchen widget test. |
| `flutter build apk --debug` | builds (Kotlin compiles) |

### Manual hardware tests still required
No Android device or printer was connected, so none of these have been run.
1. **For each connection type** (Bluetooth, USB, LAN) at 58mm and 80mm: print a KOT, an add-on round, a void ticket and a reprint. Check size, alignment, wrapping, feed and cut.
2. **Raster:** Compatibility and Full-image mode with Hindi item names, ₹ and emoji; adjust the darkness threshold.
3. **USB:** first connection shows the permission dialog; Allow, then Retry prints. Send a long receipt over 16 KB.
4. **Bluetooth on Android 12+:** the permission prompt appears; refusing shows the message. With two Bluetooth printers, a KOT and a bill go to the right devices.
5. **Recovery:** unplug or turn off a printer during a KOT. The ticket shows Print failed and Retry prints it once. Closing the app mid-print marks the job "may already have printed".
6. **Test screen (native engine):** the bill shows the business-profile details and no sample GSTIN or "PAID".

### Known limitations
- **Delivery isn't confirmed:** "Printed" means the transport accepted every byte. The printer's paper or status isn't read back.
- **Old engine still offered:** the native Kotlin engine is still used only by the Test screen. Queued jobs use the Dart engine. Retiring one of them is for Phase 11, after hardware comparison.
- **Plain ASCII in fast mode:** no printer code page is selected, so Fast mode prints plain ASCII.
- **No KOT per printer type:** each station's printers all get the same layout.
- **No ticket after a cleared job:** Reprint rebuilds from the ticket, so it still works. Only the status display loses history once jobs are cleared.
- **USB permission:** after tapping Allow, the job must be retried (manually or with the next send); there is no broadcast receiver that resumes it automatically.

---

## 14. Phase 5 completion report (2026-11-07)

### Commit
- `Phase 5` — schema v5, bill calculator, bill repository, tax bill layout, billing screens, tests and this report.

### Database migration v4 → v5
- New tables (all `ON DELETE RESTRICT`):
  - `bills`: order, bill prefix + sequence (unique together), bill number (unique), business date, status `finalized | voided`, copies of order no, type, table, customer, staff, the business header (JSON), every total (items, discount, service charge, tax, round off, grand total), the rounding mode and the full billing settings used (JSON), client request id (unique), void time and reason.
  - `bill_lines`: one row per billed line with name, variant, add-ons, qty, rate, gross, discount share, tax rate, inclusive flag, split mode.
  - `bill_taxes`: the tax breakdown per rate group (taxable value, CGST, SGST, IGST, other).
- `migration_test.dart` checks every upgrade path to v5 and v1 → v5 with data.

### Bill calculation (`lib/domain/billing/bill_calculator.dart`, pure Dart, integer paise)
1. Line gross = unit price × billable qty (voided units are never billed).
2. The order discount is shared across lines in proportion to gross, using the largest-remainder method so the shares add up exactly.
3. Lines are grouped by tax rate, inclusive/exclusive and split mode, and tax is calculated once per group on the discounted value:
   - Exclusive: tax = value × rate (added on top).
   - Inclusive: tax = value × rate ÷ (100% + rate); taxable value = the rest. The customer pays the menu price.
   - CGST + SGST: each half is calculated and rounded on its own, so the two amounts are always equal. IGST and "single line" give one amount.
   - Half-up rounding to the paisa.
4. Service charge (if configured for the order type) = rate × item taxable value (after discount, before tax), with its own configurable tax rate and split.
5. The total is rounded as configured; the difference is printed as **Round off**.
- Identity checked on 500 random orders: total = items − discount + service charge + exclusive tax + round off.

### Settings (Settings › **Billing & tax**, stored as `billing_settings`)
- Service charge % and the order types it applies to; tax on the service charge and how it is shown.
- Rounding: none (default, unchanged from before), nearest ₹1, nearest 50 paise, always down, always up.
- Bill number prefix (up to 10 letters, digits, `/`, `-`); each prefix has its own sequence starting at 1, so a new prefix such as `FY27/` restarts numbering. Numbers are never reused.
- Defaults change nothing: no service charge, no rounding, no prefix. The screen states that the business must confirm its own tax settings; changes are audited and apply only to new bills.

### Bill lifecycle (`BillRepository`, all transactional and audited)
- **Preview:** calculates without saving.
- **Finalize:** in one transaction writes the bill, lines and tax breakdown, copies the business profile, sets the order to **billed** (shown as "Payment pending"), writes audit rows on the order and the bill, and queues the bill print.
  - Same request id → same bill (double taps make one bill).
  - If the total differs from what staff saw in the preview, nothing is saved and the new total is shown.
  - Items never sent to the kitchen need confirmation (the preview warns).
  - An empty order cannot be billed.
- A **billed** order cannot be edited ("Void the bill to make changes"), still occupies its table, and blocks a second order on that table unless staff choose to share.
- **Void:** needs a reason; the bill and its number are kept, marked VOIDED; the order opens again; the next bill gets a new number.
- **Print / reprint:** the first print of a bill saved without printing is a normal print; any later copy is marked **\*\*\* DUPLICATE \*\*\***. A voided bill cannot be printed. Reprinting creates no bill.
- Menu, profile and settings changes never change a finalized bill (tested).

### Printed bill (`ReceiptLayouts.taxBill`, 58mm and 80mm)
Business name, address, phone, GSTIN and FSSAI (each only if set); bill number; date and time; order number, type and table; customer, phone and staff (if set); item, qty, rate and amount with add-ons; subtotal; discount with reason; service charge; each tax line as "CGST 2.5% on 450.00"; inclusive tax as "Incl. …" with a note that it is already in the prices; round off; TOTAL; footer. The print job carries the full bill, so a reprint is identical.

### Screens
- **Order screen:** **Generate bill** (filled when everything is in the kitchen) opens the bill preview: lines, the full breakdown, any unsent-items warning, and **Save & print** / **Save without printing**.
- **Billed order:** blue banner "Bill N · ₹total · waiting for payment"; the totals area shows the bill breakdown; **Bill & print** opens the bill (print status, Retry print, Print/Reprint, Void bill); **Void bill** asks for a reason.
- **Tables:** a billed table shows "Payment pending · #n" in blue with the bill total.
- **Orders:** billed orders stay in the running list with a "Payment pending" filter and show the bill total.

### Tests and commands
| Command | Result |
|---|---|
| `dart format lib test` | clean |
| `flutter analyze` | 13 infos (unchanged); no warnings or errors |
| `flutter test` | **173/173 passed**. New: bill calculator (17: exclusive, inclusive, IGST, mixed rates with discount, exact discount shares, voids, every rounding mode, service charge rules, 500-order random identity check); bill repository (14: finalize, idempotency, changed total, unsent items, empty order, billed order locked and table busy, void and rebill, history unchanged after menu/settings/profile edits, service charge and rounding, prefixes, validation, first print vs duplicate, reprint); bill layout (3: 58/80mm content, duplicate and empty fields, JSON round trip); generate-and-void widget flow; migration v5. |
| `flutter build apk --debug` | builds |

### Manual tests still required
No device or printer was connected.
1. Print bills at 58mm and 80mm over Bluetooth, USB and LAN: alignment of the Item/Qty/Rate/Amount columns, long item names, tax lines, total in tall text, footer.
2. Compare a few bills against your own calculation for your real tax profiles (inclusive and exclusive), discount and service charge settings.
3. Save without printing, then Print (normal), then Print again (DUPLICATE).
4. Void a bill, edit the order, and bill again: new number, old bill shows VOIDED.

### Known limitations
- **No payments yet:** a billed order stays "Payment pending" until Phase 6 adds the payment ledger (cash, UPI recording, split and partial). The bill does not yet print amount paid, balance or payment method. Phase 6 must block voiding a bill that has payments.
- **"Bill requested"** is not a separate table state; a billed table shows "Payment pending".
- **Discounts:** order-level only (shared across lines for tax). No item-level discount.
- **Tax lines** are grouped by rate, not printed per item; HSN/SAC codes are not stored or printed.
- **Bill numbering** is per prefix; changing the prefix each financial year is manual. The app does not check legal invoice-number rules.
- **The native Kotlin engine** (Test screen only) still uses the old generic bill layout.

---

## 15. Phase 6 completion report (2026-11-07)

### Commit
- `Phase 6` — schema v6, payment ledger, payment and dues screens, printed payments and receipts, tests and this report.

### Database migration v5 → v6
- New table `payments` (the ledger), `ON DELETE RESTRICT` to bills and orders:
  - kind `payment | reversal`, method `cash | upi | card | other` (+ name for other), amount (always positive), cash received and change, reference (UPI UTR, card slip…), confirmation (`staffConfirmed` for UPI/card/other), `reverses_payment_id` (unique: one reversal per payment), reason, staff name, business date of the money movement, unique client request id, time.
  - Indexes on bill, order and business date.
- `orders.due_note` (default empty).
- `migration_test.dart` checks every path to v6 and v1 → v6 with data.

### Ledger rules (`PaymentRepository`, all transactional and audited on the order and the payment)
- Entries are only inserted, never updated or deleted. A wrong or refunded payment gets a **reversal** entry with a reason; the original stays.
- Paid / part paid / unpaid and the balance are always calculated from the entries (`BillPaymentSummary`), never stored.
- A payment must be above ₹0 and no more than the balance. Cash received may be more: the change is recorded. A voided bill cannot be paid.
- UPI, card and other payments require staff to confirm they checked the money arrived; they are stored and printed as **staff-confirmed (not bank-verified)**. Showing or printing a QR never records anything.
- Same request id → one payment (double tap safe).
- **The order follows the ledger:**
  - Balance reaches ₹0 → order **settled** (table freed).
  - A reversal on a settled order → **due** (table stays free; the balance is visible again).
  - **Move to dues:** a billed order with a balance can be closed as due (needs customer name or phone, optional note); the table is freed.
  - A ₹0 bill (e.g. 100% discount) settles at once.
- A bill with money paid on it cannot be voided until the payments are reversed.
- Customer name, phone and notes can still be edited on billed and due orders (they change no amount; the finalized bill keeps its copy).

### Scenarios tested (₹500 bill)
Fully cash with change; fully UPI (rejected without staff confirmation); ₹200 cash + ₹300 UPI; ₹100 now + ₹400 later (due listed in between, earlier entry kept); ₹200 UPI + ₹300 cash; card and a named other method; overpayment, ₹0 and short cash rejected; reversal (kept, balance reopened, settled → due, no double reversal, no reversal of a reversal, then paid again); void blocked while paid; move to dues and later settle; day totals by method net of reversals.

### Printing
- **Bill** (print or reprint) now lists each payment ("Paid Cash", "Paid UPI (staff-confirmed)", "Reversed …"), references, total paid, and **BALANCE DUE** or "Paid in full".
- **Payment receipt** (optional after each payment or reversal, or later from the payment history): bill number and total, this payment and method, cash received and change, reference, reason for reversals, "Recorded by staff (not bank-verified)" for UPI/card/other, total paid and balance.
- **UPI QR on bills** (Settings › Billing & tax, off by default): a `upi://pay` QR for the amount due, using the business profile's UPI ID.

### Screens
- **Order screen (billed / due / paid):** banner with bill number, total and status (Unpaid, Part paid + balance, Due + note, Paid); breakdown with Paid and Balance due; **Collect payment · ₹balance**; **Move to dues**; **Void bill** (only while nothing is paid); **Bill & payments**.
- **Payment screen:** bill total, paid before, balance; Cash / UPI / Card / Other; amount (defaults to the full balance); for cash, cash received with quick ₹100/200/500/2000 and the change; for UPI, the QR for the full balance (if a UPI ID is set) and a warning that a QR or screenshot is not proof; reference field; a required "I checked…" tick for non-cash; optional receipt; a confirmation dialog before recording. The button says **Record UPI payment** etc.
- **Bill sheet:** payment history (time, method, staff-confirmed, reference, change, reason; reversed entries struck through) with **Print receipt** and **Refund / reverse…**; Collect; Void only while unpaid.
- **Orders › Dues & payments:** *Dues* lists every bill still owing (customer, note, balance of total); *Today* shows net totals per method, net collected, and every entry of the business day.
- The Orders list shows Due (red) and Paid orders in today's closed list.

### Tests and commands
| Command | Result |
|---|---|
| `dart format lib test` | clean |
| `flutter analyze` | 13 infos (unchanged); no warnings or errors |
| `flutter test` | **197/197 passed**. New: payment ledger (16), payment print layouts (2), part-cash-then-UPI widget flow; migration v6. |
| `flutter build apk --debug` | builds |

### Manual tests still required
No device or printer was connected.
1. Record cash (with change), UPI, card and split payments on a phone; check the confirmation dialog and messages.
2. Scan the on-screen UPI QR with a UPI app: it should open with your UPI ID, name and the amount. Do not treat the scan as payment.
3. Print a bill after a part payment (paid lines + balance), a payment receipt and a reversal receipt at 58mm and 80mm; with "Print UPI QR on bills" on, scan the printed QR.
4. Move a part-paid bill to dues, start a new order on that table, then settle the due from Orders › Dues.

### Known limitations
- **No bank verification:** UPI, card and other are staff-recorded only. Nothing is checked online.
- **Advances before billing** (e.g. booking deposits) are not supported; part payments are taken against the finalized bill.
- **Reversals are whole payments:** to refund part of a payment, reverse it and record the correct amount again. A reversal records the money going back; the app does not send UPI or card refunds.
- **No credit notes:** refunding a paid bill does not change the bill or its tax; voiding a bill still requires reversing payments first.
- **Staff names** are empty until Phase 9 (staff and permissions); reversals are not yet restricted by permission.
- **Cash drawer** (opening cash, expenses, counted cash, closing) comes in Phase 7; *Today* totals are per business day, not per shift.
