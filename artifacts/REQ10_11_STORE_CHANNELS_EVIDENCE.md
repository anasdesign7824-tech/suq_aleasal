# REQ-10/REQ-11 — قنوات المتجر والتسليم

## النطاق

أُضيف عقد حفظ قنوات المتجر من مالك المتجر فقط، ثم رُبط بعقد Flutter وواجهة `MerchantStoreEditorScreen`. القنوات المنظمة هي WhatsApp وTelegram والموقع الإلكتروني بصيغة `http://` أو `https://`. طرق التسليم تُرسل كأكواد canonical، ونقاط الاستلام تُضاف كعناصر منفصلة لا كسلسلة مفصولة بفواصل.

## Production migration

تم تطبيق migration باسم `merchant_store_channels` في مشروع Supabase Production `gvalqfgxrkibuydoiuiz`.

| العنصر | النتيجة |
|---|---|
| اسم migration | `merchant_store_channels` |
| version | `20260822072206` |
| الدالة | `public.merchant_save_store_channels(uuid, jsonb, jsonb, jsonb)` |
| الصلاحية | `security invoker`، وتنفيذ لـ`authenticated` فقط |
| حماية الملكية | يتحقق من `auth.uid()` و`stores.merchant_id` مع `FOR UPDATE` |
| الاستبدال | يستبدل روابط التواصل وخيارات التسليم ونقاط الاستلام داخل transaction الدالة |

## Probe rollback

نُفذ probe في transaction صريحة مع `ROLLBACK` في النهاية، ولذلك لم يغيّر fixture الحالي. استخدم مالك المتجر `4e658ebb-4b2f-4c01-8ee8-e56fc201c673` والمتجر `32fb6bdd-ceb4-4a8b-b6a1-1ac92c466c47`.

| الحالة | النتيجة المثبتة |
|---|---|
| owner save | نجح RPC بالقيم `whatsapp=https://wa.me/967711111111` و`telegram=https://t.me/assalkom_probe`، و`courier` و`merchant_delivery`، ونقطة استلام مؤقتة |
| customer_stores projection | أعادت القنوات العامة، `contact_whatsapp`، الاسمين العربيين `شركة توصيل` و`توصيل التاجر`، ونقطة الاستلام |
| owner retry | بعد الاستدعاء بالقيم نفسها كانت الأعداد `social=2` و`delivery=2` و`pickup=1`، ما يثبت الاستبدال دون تكرار |
| non-owner | رُفض بـSQLSTATE `P0001` |
| anon | رُفض بـSQLSTATE `P0001` |
| cleanup | انتهى probe بـ`ROLLBACK` |

## Flutter/API

أُضيف `AssalStoreChannelsDraft` إلى contracts، وتوقيع `saveMerchantStoreChannels` إلى `AssalRepository`. ينفذ `ProductionRepository` استدعاء RPC ويحوّل صف `customer_stores` إلى `AssalStoreSummary`. ينفذ `DemoRepository` نفس العقد محليًا ويحافظ على labels التسليم ونقاط الاستلام.

واجهة التاجر في `MerchantStoreEditorScreen` تعرض ثلاثة حقول URL، checklist لطرق التسليم الثلاث canonical، وحقل إضافة نقطة استلام مع `InputChip` للحذف. حارس الحفظ يمنع الروابط التي لا تبدأ بـ`http://` أو `https://`، وتبقى عملية حفظ بيانات المتجر ثم القنوات busy-guarded؛ لا تُغلق الشاشة عند فشل حفظ القنوات.

## الاختبارات والبوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze --no-pub` من `apps/mobile_flutter` | PASS — No issues found |
| `flutter test --no-pub test/merchant_store_channels_test.dart` | PASS — 3 tests |
| `flutter test --no-pub` (full mobile suite) | PASS — 70 tests |
| `git diff --check` للملفات المستهدفة | PASS |

اختبارات REQ-11 تغطي ظهور الحقول، رفض URL غير صالح قبل استدعاء repository، وتخزين القنوات في DemoRepository مرتين دون duplication.

> لم تُدّعَ مزامنة Realtime أو تسليم أحداث بين جهازين أو OTP حي في هذه المهمة. هذه الخطوة تثبت عقد الحفظ والقراءة والـRLS والواجهة؛ اختبار الجهازين وOTP الحي يبقيان بوابتين منفصلتين.
