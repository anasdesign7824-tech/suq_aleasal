# محضر بوابة Customer App — عسلكم

**تاريخ المحضر:** 16 أغسطس 2026

**النطاق:** تطبيق العميل فقط بنسختي Flutter Web وAndroid APK. لا يشمل Admin Web أو Landing/Cloudflare أو تنفيذ Supabase/RLS نفسه.

## القرار التنفيذي

> **القرار: Customer App CONDITIONAL GO للتسليم إلى حزمة Backend/Auth، وNO-GO للإطلاق الإنتاجي العام في هذه اللحظة.**

هذا القرار ليس رفضًا لجودة حزمة العميل؛ بل فصل ضروري بين اكتمال واجهة العميل وعقودها واختبارها، وبين متطلبات لا يمكن إعلانها مكتملة دون مفاتيح التوقيع، مزود OAuth، مصدر بيانات إنتاجي، وRLS. لا توجد أزرار ميتة في المسارات التي ينفذها Demo، ولا يوجد Checkout؛ التطبيق يحافظ على نموذج الاكتشاف والتواصل والطلبات والتسليم.

## الأدلة التي اجتازت البوابة

| المجال | حالة الإثبات | الدليل |
|---|---|---|
| Architecture | PASS | Feature-First facade ووحدات discovery/catalog/social/account/favorites وعقود Domain/Data مستقلة |
| Arabic/RTL | PASS في boot والكود، visual audit يدوي جزئي | `MaterialLocalizations`، locale ar، `Directionality`، IBM Plex Sans Arabic، responsive shell |
| Demo independence | PASS | DemoRepository وكتالوج غني مترابط بلا Supabase أو إنترنت |
| Dataset | PASS للـ seed contract | 10+ متاجر، 40+ منتجًا، 10+ تصنيفات، banners، popular searches، reviews/comments/requests/messages/notifications |
| Guest Discovery | PASS | التطبيق يفتح Home مباشرة بلا login wall؛ widget/navigation tests |
| Home/Search | PASS وظيفيًا | carousel، popular searches، category filters، Honey Filters، rails، unread badge |
| Product/Store | PASS وظيفيًا | gallery، metadata، honey identity، price-as-discovery، delivery/pickup، social links/gallery |
| Social/Requests | PASS في Demo journey | follow/favorite/like/review/comment/request/handoff/message/read notification |
| Merchant conversion | PASS في Demo | typed form، validation، persisted Demo application، notification |
| Web artifact | PASS للبناء والخدمة | `flutter build web --release`، static server يعيد 200 لـ `index.html` و`main.dart.js` |
| APK artifact | PASS للبناء | `flutter build apk --debug` و`flutter build apk --release` |
| Mimo runtime | PASS smoke | release APK installed successfully، `MainActivity` foreground، لا `FATAL` في نافذة logcat |
| Static quality | PASS | `flutter analyze --no-pub`: `No issues found!`; `flutter test`: 6/6 |

## شروط تحويل Conditional GO إلى Production GO

| الشرط | سبب عدم إعلانه PASS الآن | مالك الإجراء التالي |
|---|---|---|
| Production data | ProductionRepository يملك gateway boundary، لكنه ينتظر مصدر Supabase/API فعليًا | حزمة Supabase/Backend |
| Auth/OAuth | Demo يرفض Google بوضوح، وProduction يعلن provider غير مهيأ | Backend/Auth |
| RLS/security | لا يمكن إثبات ownership وparticipant policies من تطبيق العميل وحده | Backend/RLS |
| APK signing | release artifact مبني، لكنه لا يحمل keystore متجر المستخدم | صاحب المنتج/DevOps |
| Browser visual audit | HTTP والبناء نجحا، لكن جلسة المتصفح المرئي لم تتصل؛ لا يجوز تحويل ذلك إلى PASS بصري | QA على Chrome/Edge |
| Accessibility manual audit | Semantics الأساسية موجودة، لكن keyboard/focus/text-scale scanner لم يُنفذ | QA |
| Real seed migration | بيانات Demo مترابطة لإثبات السلوك وليست بديلًا عن بيانات السوق الإنتاجية | Data/Backend |

## قرار الانتقال

**لا يبدأ أي مسار مستقل لـ Admin Web أو Landing/Cloudflare أو Supabase/Backend/RLS قبل إغلاق شروط Customer App GO أدناه واعتمادها رسميًا.** حزمة العميل تملك الآن عقودًا واضحة ونقاط حقن Production ومصفوفة اختبارات قابلة لإعادة التشغيل، لكن ذلك يثبت الجاهزية الهندسية للحزمة ولا يساوي اجتياز بوابة الإطلاق أو الانتقال. لا يجوز نشر APK/Web للجمهور أو تسميتهما production-ready قبل إغلاق الشروط أعلاه، ثم إعادة إصدار قرار GO صريح.

> **الخلاصة:** حزمة Customer App قابلة للتسليم الهندسي إلى طبقة Backend/Auth، ومثبتة بالبناء والاختبار وMimo smoke. أما الإطلاق العام فهو NO-GO حتى يتم ربط البيانات والمصادقة وRLS والتوقيع والتدقيق البصري اليدوي.
