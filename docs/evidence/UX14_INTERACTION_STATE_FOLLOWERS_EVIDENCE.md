# UX-14 — حالة تفاعل المنتج وقائمة متابعي المتجر

## النطاق

أضيفت قراءة حالة الإعجاب والحفظ لكل مستخدم عند فتح تفاصيل المنتج، مع بقاء عمليات التبديل الحالية كما هي. كما أضيفت قائمة متابعين آمنة من ناحية الخصوصية، وتعرض الاسم العام والصورة العامة وتاريخ المتابعة فقط.

## التنفيذ

- أضيف `AssalProductInteractionState` إلى عقود المجال.
- أضيف `AssalStoreFollowerSummary` و`AssalStoreFollowersPage` مع pagination.
- أضيفت `loadProductInteractionState` و`listStoreFollowers` إلى `AssalRepository`.
- يقرأ Production حالة `product_likes` و`favorites` بفلاتر `user_id` و`product_id` بالتوازي؛ سياسات RLS القائمة تقيد القراءة بمالك الصف أو الصلاحيات الإدارية.
- أضيف RPC `customer_list_store_followers` في migration `0066_customer_store_followers.sql`. الدالة `security definer`، وتتحقق من جلسة authenticated ومن أن المتجر active، وتعيد فقط `display_name` و`avatar_url` و`followed_at` بلا البريد أو الهاتف أو `user_id`، مع حد أقصى 100 عنصر وpagination.
- أضيفت واجهة نقر على رقم المتابعين في رأس المتجر وتعرض Dialog حقيقيًا أو رسالة خطأ واضحة.
- أضيفت حواجز busy لزرّي الإعجاب والحفظ لمنع الطلبات المكررة.
- DemoRepository يحافظ على parity محلي للحالة وقائمة المتابع الحالي عند المتابعة.

## التحقق

- Supabase `apply_migration`: نجاح تطبيق migration في Production.
- فحص RLS السابق: `profiles` لا يسمح بالقراءة العامة، و`store_followers` لا يسمح بقراءة القائمة لغير المالك/المتابع/admin؛ لذلك لم تُكشف الجداول مباشرة، واستُخدم RPC محدود البيانات.
- `flutter analyze`: `No issues found!`.
- `flutter test test/ux14_interaction_state_test.dart`: **3 اختبارات ناجحة**.

## حدود الإثبات

لم يُدّع اختبار جهاز Android فعلي أو اختبار حسابين حقيقيين؛ ذلك يتطلب جهازًا/محاكيًا وجلسات Production فعلية. لم تُكشف أي بيانات اتصال حساسة عبر هذا المسار.
