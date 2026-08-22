# UX-07 — أفعال التواصل ذات feedback

## ما تغير

كان زر `مراسلة التاجر` يستدعي `createConversation` ثم يعود بصمت عند الفشل؛ لذلك يبدو الزر شكليًا. أصبح له busy guard يمنع الضغط المزدوج، ومؤشر تحميل، ورسالة خطأ مأخوذة من `AssalError.messageAr`. عند النجاح ينتقل إلى شاشة المحادثة، وعند الفشل يبقى المستخدم في صفحة المتجر مع feedback واضح.

## الاختبار

| البوابة | النتيجة |
|---|---|
| `flutter analyze --no-pub` | PASS — No issues found |
| `store_contact_ux_test.dart` | PASS — الفشل يظهر والزر يبقى موجودًا |
| `store_profile_ux_test.dart` | PASS |

لم يتغير عقد المحادثة أو RLS أو backend. هذا الإصلاح يزيل حالة الصمت من الواجهة فقط.
