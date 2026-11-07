# Device and printer test checklist

Run this on real hardware before each release. Automated tests cover the logic: `flutter test` runs 279 tests, including migrations, the payment ledger, billing, stock, staff, and backup and restore. They cannot cover printers, Android permissions, slow devices or real money.

Write the device, Android version, printer model and date next to each section. Mark each line ✅ pass, ❌ fail (with a note) or — not applicable.

## 0. Install and upgrade
- [ ] Fresh install on an empty phone or tablet: the app opens and the Tables tab shows.
- [ ] **Upgrade over the previous version that has real data:** all of these are still there:
  - printers, settings and the print queue;
  - menu, orders, bills, payments and shifts.
- [ ] Settings > App error log shows "No errors recorded" after normal use.

## 1. Orders and billing (master prompt, Part H)
- [ ] Create a dine-in order (with a table) and a takeaway order.
- [ ] Add items with variants and add-ons. Change a quantity and add notes.
- [ ] Send a KOT. Add an item and send again: **only the new item** prints.
- [ ] Void an item that was already sent: a void / cancellation KOT prints, and the reason is required.
- [ ] Finalize the bill and check the totals by hand: items, discount, service charge, tax, round off.
- [ ] Change a menu price. Old bills (open, reprint, report) still show the old price.
- [ ] Void a bill with a reason, then bill again: a new bill number is issued and the old bill is shown as voided.

## 2. Payments (₹500 bill each)
- [ ] All cash, with change worked out correctly (e.g. ₹2,000 given).
- [ ] All UPI: it is marked **staff-confirmed**, never "verified".
- [ ] ₹200 cash + ₹300 UPI.
- [ ] ₹100 cash now, ₹400 later (dues): it shows Part paid, then Paid.
- [ ] ₹200 UPI now, ₹300 cash later.
- [ ] After every payment the status and balance are right.
- [ ] Double-tap Pay, or tap it on a slow device: only **one** payment is saved.
- [ ] Reverse a payment with a reason: the original payment stays and the reversal is listed under it.

## 3. Printers
For each transport you use, and for each paper width:
- [ ] Bluetooth printer: pair, test print, bill, KOT.
- [ ] USB printer: permission prompt, test print, bill, KOT.
- [ ] LAN / Wi-Fi printer: IP and port, test print, bill, KOT.
- [ ] 58 mm and 80 mm: wrapping, alignment, cutting and paper feed are right.
- [ ] English, Hindi (Devanagari), the ₹ sign, symbols, emoji (raster) and the logo print readably. Adjust darkness if needed.
- [ ] Turn the printer off during a job: the job fails with a reason. Turn it on and retry: it prints **once**.
- [ ] Close the app with jobs pending and reopen it: the jobs are still in the queue.
- [ ] Retrying or reprinting never makes a new bill, KOT, payment or stock movement. Reprints are marked DUPLICATE / REPRINT.
- [ ] Shift report, sales report (with and without item-wise sales) and payment receipt print at both widths.

## 4. Offline (airplane mode, whole service)
- [ ] Create orders, change the menu, and print to Bluetooth / USB, plus LAN on the local network.
- [ ] Record cash and UPI, view reports, close the shift.
- [ ] Force-close and reopen the app: everything is still there.
- [ ] Nothing in the app asks for internet.

## 5. Shift and cash drawer
- [ ] Open a shift with opening cash. Record cash in and out, and an expense paid from the drawer.
- [ ] Close the shift with a counted amount that differs: a reason is required, and the report shows short or over.
- [ ] UPI and card are not counted as drawer cash.

## 6. Reports
- [ ] After a real day, check the Summary by hand against the bills, the drawer and the UPI app:
  - total billed;
  - cash, UPI and card collected;
  - dues.
- [ ] The ledger check shows OK.
- [ ] Export CSV and open it in Excel or Google Sheets: ₹ and Hindi show correctly, and amounts are numbers.
- [ ] Note how long "This month" takes to open on the slowest device: ______ s.

## 7. Staff and permissions
- [ ] Set up the owner and write down the recovery code. Add a cashier and a waiter.
- [ ] As each role: check which tabs show, and that blocked actions ask for approval. A manager PIN allows **one** action.
- [ ] Enter 5 wrong PINs: the account locks. Restart the app: it is still locked.
- [ ] Auto-lock in the middle of an order: sign back in and the order is still there.
- [ ] PIN sign-in on the slowest device takes ______ s (should be well under 1 s).
- [ ] Use the recovery code once: a new code is shown.

## 8. Stock (if used)
- [ ] Add 5–10 ingredients with opening stock and recipes.
- [ ] Run a service in "When sent to the kitchen" mode, then in "When the bill is made" mode. Count stock at closing and compare.
- [ ] Reprinting a KOT or bill and retrying a failed print do not change stock.
- [ ] A bill void gives the stock back (bill mode).

## 9. Backup and restore
- [ ] Create a **password-protected** backup and share it off the device (Drive or computer).
- [ ] Create a backup without a password: it is marked "verified".
- [ ] Restore the protected backup on the **same** device:
  1. A wrong password is refused.
  2. The summary shows the right counts.
  3. You have to type RESTORE.
  4. "Close app now", then reopen.
  5. The data is back; a green banner says it was restored and names the pre-restore backup.
- [ ] Restore it on a **second** device: the same staff PINs work there.
- [ ] Restore the pre-restore backup: the data from before the restore comes back.
- [ ] "Cancel restore" before closing the app: nothing changes.

## 10. Accessibility and layout
- [ ] Android font size at largest, and display size large: the Tables, order, payment, Shift, Reports and Settings screens are usable, with no clipped buttons.
- [ ] Use a tablet in landscape: the side rail shows and the active order is visible next to the menu.
- [ ] TalkBack: the PIN pad says the number of digits entered, and icon buttons say what they do.
- [ ] A hardware keyboard or barcode scanner types into menu search, and the PIN pad accepts digits and Enter.

## 11. Crash handling
- [ ] After testing, Settings > App error log has no unexpected errors. Share it with the developer if it has any.
