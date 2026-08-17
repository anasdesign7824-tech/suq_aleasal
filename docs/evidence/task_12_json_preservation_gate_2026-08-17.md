# Task 12 — لا تحذف محتوى JSON

## Task Scope

حماية كل محتوى JSON المرجعي والتشغيلي من الحذف أو الاختصار لمجرد تقليل الحجم، مع تسجيل أي اختلاف بين نسخ Demo بدل حذف نسخة أو استبدالها بصمت.

## Findings

يوجد ملفان Demo مقصودان بنطاقين مختلفين:

| الملف | النطاق المثبت | المحتوى الحالي |
|---|---|---|
| `packages/demo_data/data/demo_catalog.json` | Minimal package fixture لأدوات/اختبارات Demo | 4 مناطق، 3 متاجر، 30 منتجًا، إشعارات وطلبات محددة، ومراجعات فارغة |
| `apps/mobile_flutter/assets/demo_catalog.json` | Rich Flutter runtime catalog | 10 مناطق، 10 متاجر، 50 منتجًا، 5 بنرات، 6 إشعارات، 8 تعليقات، 3 محادثات، 6 رسائل، 8 طلبات، و12 مراجعة |

اختلاف الحجم والمحتوى ليس حذفًا جديدًا نتج عن هذه المهمة؛ بل كان موجودًا قبلها. تم تسجيله صراحةً بدل توحيد الملفين بتقليص النسخة الأغنى أو إضافة محتوى مصطنع إلى النسخة المصغرة.

## Changes

أُضيفت `tools/compare_demo_jsons.py` لتقرأ النسختين وتطبع:

- top-level keys.
- أعداد المناطق والمتاجر والمنتجات والبيانات الاجتماعية.
- مفاتيح الاختلاف وأطوال القوائم.
- PASS واضح عند حفظ النسختين ضمن نطاقين معلنين، مع منع الحذف التلقائي.

تم تعديل الأداة لتعتبر divergence المسجل نتيجة تدقيق ناجحة، لا سببًا لحذف أحد المصدرين.

## Files Changed

| الملف | التغيير |
|---|---|
| `tools/compare_demo_jsons.py` | مقارنة وحماية النسختين دون حذف |
| `docs/evidence/task_12_json_preservation_gate_2026-08-17.md` | دليل البوابة |

لم يُحذف أي سطر من `references/data/yemeni_honey_master_database_final.json` أو `packages/demo_data/data/demo_catalog.json` أو `apps/mobile_flutter/assets/demo_catalog.json`.

## Tests

| الفحص | النتيجة |
|---|---|
| `python3 tools/compare_demo_jsons.py` | PASS — اختلاف النطاقات موثق ولا حذف تلقائي |
| `python3 -m json.tool packages/demo_data/data/demo_catalog.json` | PASS |
| `python3 -m json.tool apps/mobile_flutter/assets/demo_catalog.json` | PASS |
| `python3 tools/check_demo_catalog.py` | PASS |
| `python3 tools/analyze_honey_master.py` | PASS |

## Runtime Verification

لم يتغير Asset runtime أو loader في هذه المهمة؛ تم التحقق من أن ملف Flutter الغني ما زال موجودًا وقابلًا للتحليل، وأن package fixture بقي محفوظًا.

## Visual Verification

لا ينطبق screenshot على أداة الحماية، لكن كل بيانات الواجهة الغنية التي كانت موجودة في runtime JSON بقيت محفوظة؛ لم تُستبدل بكتالوج أصغر.

## Architecture Verification

النسختان موضحتان بنطاقين منفصلين: package fixture لأدوات/اختبارات محددة، وFlutter runtime asset للتجربة الغنية. لا يجوز مستقبلاً تغيير أحدهما إلا بتحديث manifest ودليل النطاق.

## Data / Contract Verification

كل الملفات valid JSON، وDemo runtime يبقى `demo_only` ويرتبط بإصدار المصدر `5.0.0`. أداة المقارنة لا تفترض تطابقًا زائفًا بين نسختين مختلفتي الغرض.

## Regression Verification

نجحت أدوات Honey Master وDemo Catalog، ولم يحدث حذف أو تصغير لأي JSON. Task 11 يبقى مثبتًا بأن Repository هو نقطة القراءة بدل Widgets.

## Remaining Issues

وجود نسختين Demo يتطلب استمرار توثيق النطاق عند أي تعديل لاحق؛ لا ينبغي دمجهما عشوائيًا لأن package fixture مرتبط بأدوات أخرى، بينما runtime asset هو النسخة الغنية المستخدمة داخل Flutter.

## Final Gate

**PASS** — لم يُحذف أي محتوى JSON، وتمت إضافة مقارنة حتمية تسجل اختلاف النطاقات وتحمي النسختين من الحذف الصامت.
