# TASK 098 — UI Consistency Evidence

## النتيجة

**PASS — تم توحيد قاموس الحالات والأنواع والأحداث الظاهرة في Admin مع semantics العميل، وإزالة fallbackات identifiers التقنية من الواجهة.** التغيير محافظ ومحصور في طبقة العرض وutility مشتركة واختبارات unit، دون تعديل قاعدة البيانات أو عقود RPC.

## الحالة قبل الإصلاح

أظهر source audit تناقضات قابلة للإثبات:

| الموضع | السلوك قبل الإصلاح | المشكلة |
|---|---|---|
| `Home.tsx` | `statusBadge` يعرض `label: status` عند الحالة غير المعروفة | قد يظهر wire status خامًا للمستخدم، بدل حالة عربية آمنة. |
| `Home.tsx` | جدول المنتجات يعرض `product.product_type` مباشرة | تظهر قيم مثل `honey` و`wax` بدل قاموس العميل العربي. |
| `Home.tsx` | بعض الحالات تستخدم معنى مختلفًا عن domain؛ مثل طلب التواصل `open` كان يُعرض `جديد`، والمتجر المعلّق كان قريبًا من `موقوف` | اختلاف بين العميل والإدارة في معنى الحالة واللون. |
| `Home.tsx` | تفاصيل المتجر تعرض `store.id` و`merchant_id` و`region_id` | كشف UUIDs/identifiers تقنية في UI لا يحتاجها المستخدم. |
| `AdminMerchantApplications.tsx` | fallback للحالة غير المعروفة كان يعرض النص الخام، وغياب الهاتف كان يعرض `user_id` | كشف identifier تقني، وعدم وجود fallback عربي آمن. |
| `AdminGovernance.tsx` | غياب البريد كان يعرض `user_id`، وغياب اسم الدور كان يعرض `role.code`، وسجل التدقيق يعرض `action` و`entity_type` wire values | تسريب أسماء تقنية وعدم اتساق المصطلحات الظاهرة. |

المصادر الخام محفوظة في `artifacts/task098_status_term_inventory_raw.txt`, `artifacts/task098_color_inventory_raw.txt`, `artifacts/task098_status_label_hits.txt`, `artifacts/task098_ui_identifier_hits.txt`, و`artifacts/task098_audit_vocab_hits.txt`.

## الإصلاح المحافظ

أضيفت `apps/admin_web/client/src/lib/ui-consistency.ts` كقاموس عرض مركزي يحتوي على:

1. `adminStatusMeta(status, context)` لسياقات `product`, `store`, `request`, و`merchantApplication`، مع labels عربية وألوان semantic متسقة.
2. fallback ثابت `حالة غير معروفة` لا يعرض قيمة wire status المستقبلية.
3. `adminProductTypeLabel` لتوحيد `honey`, `wax`, `mix`, `raw`, و`gift` مع قاموس العميل: `عسل`, `شمع`, `خلطة`, `منتج خام`, و`هدية`.
4. `adminAuditActionLabel` و`adminAuditEntityLabel` لترجمة الأحداث والكيانات المعروفة، مع `إجراء إداري` و`كيان إداري` للحالات غير المعروفة.

تم تحديث `Home.tsx` لتمرير context الصحيح لكل status badge، واستخدام product type label، وحذف حقول UUID من تفاصيل المتجر. وتم تحديث `AdminMerchantApplications.tsx` لاستخدام القاموس المركزي واستبدال fallback `user_id` بـ`لا يوجد رقم هاتف`. وتم تحديث `AdminGovernance.tsx` لاستبدال fallbackات البريد والدور، وترجمة audit action/entity قبل العرض.

المعرفات ما زالت موجودة داخل callbacks و`key` ومسارات API اللازمة لتنفيذ العمليات الإدارية، لكنها لم تعد تُعرض كنصوص في الواجهة؛ هذا فصل مقصود بين identity التشغيلية وpresentation.

## الدليل بعد الإصلاح

تم تشغيل post-patch scan مقيّد بالملفات الثلاثة المعدلة، وكانت النتيجة:

```text
NO_RAW_STATUS_PRODUCT_OR_UUID_FALLBACKS_FOUND
```

المصدر: `artifacts/task098_post_ui_consistency_scan.txt`.

اختبارات قاموس الاتساق تثبت أن:

| الحالة | النتيجة المثبتة |
|---|---|
| store `active` | `مفعّل` |
| generic `active` | `نشط` |
| request `in_progress` | `قيد المتابعة` |
| merchant application `approved` | `مفعّل — المتجر نشط` |
| unknown status | `حالة غير معروفة` دون تضمين raw value |
| product `honey` / `gift` | `عسل` / `هدية` |
| unknown product | `نوع غير محدد` |
| known audit action/entity | ترجمة عربية معتمدة |
| unknown audit action/entity | `إجراء إداري` / `كيان إداري` |

## الاختبارات والبوابات

| البوابة | النتيجة |
|---|---|
| Admin TypeScript check (`pnpm check`) | PASS |
| Admin tests | PASS — `47` اختبارًا عبر `8` ملفات، منها `4` اختبارات جديدة لـ`ui-consistency` |
| Admin production build (`pnpm build`) | PASS |
| Flutter analyze (`flutter analyze --no-pub`) | PASS — `No issues found!` |
| Flutter full tests (`flutter test --no-pub`) | PASS — `62` اختبارًا |

ظهر تحذير Vite المعتاد حول chunk أكبر من 500 kB بعد التصغير، لكنه non-blocking ولم يفشل build. لم تتغير ملفات Flutter في TASK 098؛ full Flutter gate أُعيد لتثبيت عدم وجود regression في العقد المشترك.

## حدود الإثبات

التدقيق source-based مع unit tests وbuild gates، ولم تُجرَ جلسة browser تفاعلية أو مراجعة screenshot بصرية ضمن هذه المهمة. لذلك يثبت الدليل vocabulary/semantic consistency وإخفاء identifiers في source، بينما التقييم البصري الشامل للألوان والمسافات يبقى ضمن المراجعات السابقة أو gates اللاحقة. لا يُدّعى أن كل نص عربي في المشروع أُعيدت صياغته؛ تم إصلاح التناقضات التي ثبتت في status/type/audit/identifier paths المحددة.

## الملفات

| المسار | الدور |
|---|---|
| `apps/admin_web/client/src/lib/ui-consistency.ts` | قاموس العرض المركزي للحالات والأنواع والأحداث |
| `apps/admin_web/client/src/lib/ui-consistency.test.ts` | اختبارات unknown fallback وcontext labels |
| `apps/admin_web/client/src/pages/Home.tsx` | استهلاك القاموس وإزالة UUIDs من store details |
| `apps/admin_web/client/src/components/AdminMerchantApplications.tsx` | توحيد merchant application status وإخفاء user_id fallback |
| `apps/admin_web/client/src/components/AdminGovernance.tsx` | توحيد audit labels وإخفاء email/role identifiers fallback |
| `artifacts/task098_status_term_inventory_raw.txt` | جرد الحالات والمصطلحات قبل الإصلاح |
| `artifacts/task098_color_inventory_raw.txt` | جرد الألوان قبل الإصلاح |
| `artifacts/task098_status_label_hits.txt` | hits لتعريفات status labels |
| `artifacts/task098_ui_identifier_hits.txt` | جرد identifier render paths |
| `artifacts/task098_audit_vocab_hits.txt` | جرد audit action/entity vocabulary |
| `artifacts/task098_post_ui_consistency_scan.txt` | نتيجة post-patch scan |

## الحكم النهائي

**TASK 098 = PASS.** أصبحت الحالات والأنواع والأحداث المعروفة معروضة بقاموس عربي موحد حسب السياق، unknown values لا تُسرّب إلى الواجهة، وUUIDs التشغيلية لم تعد presentation text في المسارات المعدلة. اجتازت Admin وFlutter بوابات typecheck/test/build كاملة.

## References

[1]: `apps/admin_web/client/src/lib/ui-consistency.ts`
[2]: `apps/admin_web/client/src/lib/ui-consistency.test.ts`
[3]: `apps/admin_web/client/src/pages/Home.tsx`
[4]: `apps/admin_web/client/src/components/AdminMerchantApplications.tsx`
[5]: `apps/admin_web/client/src/components/AdminGovernance.tsx`
[6]: `packages/contracts_dart/lib/assal_domain.dart`
[7]: `artifacts/task098_post_ui_consistency_scan.txt`
