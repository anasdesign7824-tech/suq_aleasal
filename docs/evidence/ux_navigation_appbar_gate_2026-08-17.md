# UX Navigation / AppBar Gate — 2026-08-17

## التغيير

تم تعديل الجذر المشترك في `AssalHomeShell` و`AssalAppBar`:

- التنقل السفلي/الجانبي أصبح خمسة أقسام: «اكتشف»، «المتاجر»، «التصنيفات»، «المراسلات»، «حسابي».
- عنصر «المتاجر» يفتح `StoresScreen(repository: repository)` الحقيقي من نفس Repository.
- `AssalAppBar` يكتشف route قابلًا للرجوع ويعرض سهم `arrow_forward_rounded` مع `maybePop` فعلي.
- الشعار المصغر المؤطر يظهر ضمن Header المشترك عند الشاشات الفرعية، بينما يبقى شعار الصفحة الرئيسية مستقلًا.
- لا يوجد زر ميت أو route خاص بــAPK واحد؛ كل التغيير في `lib/app/assal_app.dart` و`lib/core/assal_widgets.dart`.

## التحقق

| الفحص | النتيجة |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 11 tests passed |
| `git diff --check` | PASS |

## البوابة

**PASS — source-level navigation and AppBar change.**

Visual QA التفصيلي على Mimo سيُعاد في المرحلة النهائية بعد بناء النسخ من المصدر الجديد.
