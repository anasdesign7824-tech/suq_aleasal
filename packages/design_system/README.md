# Shared Design System — عسلكم

هذه الحزمة هي العقد البصري المشترك للمشروع. تعتمد على ألوان الهوية العسلية والكريمية والبنية، وعلى IBM Plex Sans Arabic، وتمنع القيم العشوائية داخل الشاشات.

## المسارات

| المسار | الاستخدام |
|---|---|
| `dart/lib/assal_tokens.dart` | توكنز تطبيق Flutter/Dart |
| `web/tokens.css` | CSS Variables لمشاريع Web |
| `web/tokens.ts` | توكنز TypeScript لمشاريع Web عند الحاجة |
| `../../docs/design-system-contract.md` | المرجع الدلالي الكامل |

يجب أن تكون أي تحويلات بين المسارين متطابقة دلاليًا. لا تتصل التوكنز بمصدر بيانات أو Supabase، ولا تحتوي على User Journey أو Feature behavior.
