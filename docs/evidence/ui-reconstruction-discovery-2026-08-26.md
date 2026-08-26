# UI Reconstruction Discovery Evidence — 2026-08-26

## Phase

Discovery and information architecture preparation for the full UI/UX reconstruction directive.

## Implemented

أُجري جرد للكود الفعلي في نسخة GitHub عند commit `e2499d4`، وشمل تطبيق Flutter، لوحة الإدارة، عقود Dart وTypeScript، مستودع البيانات، المكونات المشتركة، المصادقة، التوثيق، الصور، الرسائل، الإشعارات، الحالات، والتنقل. أُنشئت المواصفات السبعة المطلوبة قبل تعديل أي Widget أو Screen:

1. `UI_RECONSTRUCTION_DISCOVERY.md`
2. `UI_INFORMATION_ARCHITECTURE.md`
3. `UI_ENTITY_PRESENTATION_SPEC.md`
4. `UI_DESIGN_SYSTEM_SPEC.md`
5. `UI_COVERAGE_MATRIX.md`
6. `UI_GAP_REGISTER.md`
7. `UI_RECONSTRUCTION_TASK_LEDGER.md`

## Files inspected

| Area | Files |
|---|---|
| Flutter entry and shell | `apps/mobile_flutter/lib/app/assal_app.dart`, `apps/mobile_flutter/lib/core/assal_widgets.dart` |
| Customer | `customer_discovery.dart`, `customer_catalog.dart`, `customer_account.dart`, `customer_favorites.dart`, `customer_social.dart` |
| Merchant | `merchant_dashboard.dart`, `merchant_product_editor.dart`, `store_verification_screen.dart`, `subscription_plans_screen.dart` |
| Contracts/data | `packages/contracts_dart/lib/assal_domain.dart`, `packages/data_dart/lib/assal_repository.dart`, `demo_repository.dart`, `production_repository.dart` |
| Admin | `apps/admin_web/client/src/pages/Home.tsx`, `apps/admin_web/client/src/lib/admin-api.ts` |
| Existing governance | `docs/execution-authority.md`, `docs/architecture-boundaries.md`, `docs/design-system-contract.md`, `docs/evidence/unified_discovery.md` |

## Tests

تم تنفيذ فحص وجود الملفات السبعة و`git diff --check` على التغييرات الوثائقية. لم تُنفذ اختبارات Flutter أو Admin لأن هذه الخطوة لم تعدل كودًا تنفيذيًا.

## Build

لم يُنفذ Build في هذه الخطوة؛ لا توجد تغييرات تنفيذية تستدعيه.

## Visual verification

لم يبدأ الفحص البصري بعد. تم توثيق متطلبات RTL وresponsive وaccessibility ونسب الصور في المواصفات لتصبح بوابات إلزامية لكل مهمة لاحقة.

## Architecture verification

تأكدت الوثائق من الحفاظ على Flutter/Dart للموبايل، Demo-First وRepository Abstraction، فصل UI/Domain/Data، Supabase كمصدر إنتاج خلف العقد، واستخدام عقود Dart للموبايل وعقود TypeScript للويب عند الحاجة. تم تسجيل الفجوات التي لا يدعمها العقد كـ`BLOCKED` أو `OPEN` بدل اختراعها.

## Known issues

الفجوات الحالية تشمل Route Registry مركزي، Notification destinations typed، سياسة خصوصية Profile، حالات UI الثماني، عقد Following للمستخدمين، Order flow كامل غير موجود، سياق Conversation للمنتج/الطلب، تحقق Storage، وتغطية Landing التنفيذية. التفاصيل والأدلة في `UI_GAP_REGISTER.md`.

## Fixes

لا توجد إصلاحات UI تنفيذية حتى الآن، التزامًا بالأمر التنفيذي الذي يطلب إكمال Discovery والمواصفات قبل تعديل أي واجهة.

## Acceptance status

`READY_FOR_FIRST_ATOMIC_TASK` — الوثائق موجودة، والفجوات موثقة، والمهمة التنفيذية التالية المسموح بها هي `T008` فقط بعد اعتماد هذا الدليل.

## Git commit

`e05972e` — commit مستقل لمخرجات Discovery والمواصفات والحوكمة.
