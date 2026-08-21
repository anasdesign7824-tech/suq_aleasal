# TASK 082 — Orphan Records: Images, Taxonomy, Social, and Requests

**التاريخ:** 2026-08-21

**الحالة:** PASS — all scoped orphan scans returned zero

## النطاق والمنهج

تم جرد الجداول الفعلية في Production project `gvalqfgxrkibuydoiuiz` عبر `information_schema` و`pg_constraint` قبل كتابة الاستعلامات. شمل الجرد جداول الصور والمعرض، التصنيفات وربط المنتجات، التقييمات والإعجابات، التعليقات وإعجاباتها، المفضلة، الطلبات وعناصرها ورسائلها، ومسارات طلبات التصميم والدفع والتوثيق وفتح مساحة التاجر.

كل استعلامات البيانات نُفذت بصيغة `BEGIN; SELECT ...; ROLLBACK;`، مع `LIMIT` صريح وقراءة counts فقط. لم تُنشأ بيانات اصطناعية ولم تُحذف أو تُعدّل أي سجلات.

## Foreign Key inventory الفعلي

| المجال | العلاقات التي فُحصت |
|---|---|
| الصور | `product_images.product_id → products.id`، `store_gallery.store_id → stores.id`. |
| التصنيفات | `categories.parent_id → categories.id`، `product_categories.product_id → products.id`، `product_categories.category_id → categories.id`. |
| شهادات المنتج | `product_certifications.product_id → products.id`، `product_certifications.certification_id → certifications.id`. |
| التقييمات | `reviews.author_id → users.id`، `reviews.product_id → products.id`، `reviews.store_id → stores.id`، `review_likes.review_id → reviews.id`، `review_likes.user_id → users.id`. |
| التعليقات | `comments.author_id → users.id`، `comments.product_id → products.id`، `comments.review_id → reviews.id`، `comments.parent_comment_id → comments.id`، `comment_likes.comment_id → comments.id`، `comment_likes.user_id → users.id`. |
| المفضلة | `favorites.user_id → users.id`، وحقلا `product_id` و`store_id` عندما يكونان غير فارغين. |
| الطلبات | `requests.requester_id → users.id`، `requests.store_id → stores.id`، `request_items.request_id → requests.id`، `request_items.product_id → products.id`، `request_messages.request_id → requests.id`، `request_messages.sender_id → users.id`. |
| المسارات الإدارية المرتبطة | merchant applications/drafts، design requests، payment requests، store verification requests، مع فحص merchant/store/reviewer/admin/region references غير الفارغة. |

## نتائج orphan scans

| فحص العلاقة | orphan count |
|---|---:|
| `product_images → products` | 0 |
| `store_gallery → stores` | 0 |
| `product_categories → products/categories` | 0 / 0 |
| `product_certifications → products/certifications` | 0 / 0 |
| `categories.parent_id → categories` | 0 |
| `reviews → users/products/stores` | 0 / 0 / 0 |
| `review_likes → reviews/users` | 0 / 0 |
| `comments → users/products/reviews/parent_comments` | 0 / 0 / 0 / 0 |
| `comment_likes → comments/users` | 0 / 0 |
| `favorites → products/stores/users` | 0 / 0 / 0 |
| `requests → users/stores` | 0 / 0 |
| `request_items → requests/products` | 0 / 0 |
| `request_messages → requests/users` | 0 / 0 |
| design requests → merchant/store/assigned admin | 0 / 0 / 0 |
| payment requests → merchant/store/reviewer | 0 / 0 / 0 |
| store verification requests → merchant/store/reviewer | 0 / 0 / 0 |
| merchant applications/drafts → user/region/reviewer | 0 / 0 / 0 / 0 |

الاستعلام الشامل أعاد 27 check names، وكل `issue_count=0`. والاستعلام الإضافي للمسارات الإدارية أعاد 14 check names، وكل `issue_count=0`.

## Row-count snapshot وتفسير الصفر

النتيجة ليست مبنية على جداول فارغة فقط. سجل Production يحتوي على `banners=2` و`categories=9` و`comments=1` و`favorites=1` و`payment_requests=1` و`request_items=2` و`requests=2` و`reviews=1` و`store_gallery=1` و`store_verification_requests=1`. بعض الجداول، مثل `product_images` و`product_categories` و`product_certifications` و`review_likes` و`comment_likes` و`request_messages` و`design_requests` و`merchant_applications`، كانت فارغة فعليًا، ولذلك تم توثيق row counts بدل إطلاق حكم غامض.

جداول `customer_*` هي read models/views وليست جداول مصدرية مستقلة ذات FK rows، ولذلك لم تُعامل كسجلات orphan مستقلة. وجدول `banners` جذر بيانات يحتوي `image_url` ولا يملك FK إلى parent entity؛ لا يمكن تعريف orphan relational له من دون عقد إضافي، لذلك بقي خارج orphan FK count بدل اختراع علاقة.

## الأدلة الخام

| الدليل | الملف |
|---|---|
| FK inventory | Supabase result `2026-08-21_16-24-22.345248662_supabase_execute_sql_65aae788.json`. |
| orphan scan الأساسي | Supabase result `2026-08-21_16-25-03.305811397_supabase_execute_sql_4114bfb9.json`. |
| table inventory | Supabase result `2026-08-21_16-25-34.855679907_supabase_execute_sql_5121bf4b.json`. |
| orphan scan الإضافي | Supabase result `2026-08-21_16-26-05.199579527_supabase_execute_sql_2b458616.json`. |
| row-count snapshot | Supabase result `2026-08-21_16-26-39.029251027_supabase_execute_sql_ed8b2852.json`. |
| مصدر schema المحلي | `database/migrations/0001_initial_souq_al_assal.sql` والمigrations ذات الصلة بالتعليقات والطلبات والتصنيفات. |

## الحكم

**TASK 082 مغلقة PASS.** لا توجد سجلات يتيمة في العلاقات المفحوصة للصور والتصنيفات والتقييمات والتعليقات والمفضلة والطلبات والمسارات الإدارية المرتبطة. لم يوجد إصلاح بيانات مطلوب، ولذلك لم تُنفذ أي عملية حذف أو تنظيف.

لا يشمل هذا الحكم التحقق من HTTP availability لكل `image_url` أو وجود كل object داخل Storage؛ ذلك فحص مختلف عن orphan relational rows، ويُعاد تقييمه ضمن مسار Storage Security/Privacy اللاحق.
