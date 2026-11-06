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
- [ ] Phase 3 — Tables & orders
- [ ] Phase 4 — KOT + printer fixes D1, D2, D6–D12, D14
- [ ] Phase 5 — Billing & tax
- [ ] Phase 6 — Payments
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
- **Phase 3 rule to add:** once orders exist, check that a turned-off item's past orders still show it. The snapshot design covers this.
