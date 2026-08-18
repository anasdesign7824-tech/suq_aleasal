# ADMIN CONTROL MATRIX — عسلكم

هذه المصفوفة جزء من Discovery، ولا تعني أن الوظائف مكتملة. الحالة تصف ما هو موجود الآن، بينما الإجراء المطلوب يحدد نطاق التنفيذ بعد Gate 1.

| Feature | Current App Screen | Current Data | Current Contract/Repository | Current Admin Screen | Required Admin Action | Required Permission | Database Source | Status | Gap |
|---|---|---|---|---|---|---|---|---|---|
| User Profile | Profile/Account | `profiles` + Auth identity | `ProductionRepository.getSession` | لا توجد | عرض/تعطيل/مراجعة وفق الخصوصية | `user.read`, `user.manage` | `auth.users`, `users`, `profiles` | Partial | لا Admin route ولا privacy view |
| Customer activity | Profile, favorites, follows | قراءات جزئية | Repository reads، writes اجتماعية غير مهيأة | لا توجد | عرض النشاط المسموح | `user.read` | favorites, store_followers, notifications | Partial | Analytics/write gaps |
| Merchant onboarding | `BecomeMerchantScreen` | Draft/Application interface | `submitMerchantApplication` غير مهيأ Production | لا توجد | استقبال الطلب ومراجعته | `store.read`, `store.review` | merchant_profiles + stores/application model | Blocked | Write path غير مهيأ |
| Store application | Store wizard | حقول نصية أساسية | `loadMerchantApplication` غير مهيأ | لا توجد | Pending queue، تفاصيل، قرار | `store.review`, `store.approve`, `store.reject` | stores/merchant_profiles أو جدول application بعد Discovery | Blocked | لا دورة حالة مكتملة |
| Store moderation | Stores discovery | `stores.status`, `is_verified` | قراءات customer views | Demo cards فقط | approve/reject/request/suspend/reactivate | `store.review`, `store.approve`, `store.suspend` | stores + audit_logs | Partial | RLS عامة، لا Controller/UI |
| Store public discovery | Home/Stores | `customer_stores` | Production read path موجود | Demo stores | معاينة الأثر بعد القرار | `store.read` | stores, regions, customer_stores | Partial | لا E2E من admin |
| Store gallery/media | Store profile | store_gallery/URLs | Read model موجود | لا توجد | إدارة الصور العامة | `store.media.write` | store_gallery + assalkom_public | Partial | لا Upload flow |
| Verification | BecomeMerchant status | status mapping محدود | submit/load غير مهيأ | لا توجد | review evidence/decision | `verification.read/review/approve/reject` | merchant_profiles + private storage | Blocked | لا evidence upload أو workflow |
| Products | Product catalog/detail | `customer_products` | Production reads موجودة، writes Admin غير موجودة | Demo ProductTable | CRUD/review/publish/pause | `product.read/write/review/approve/reject` | products + product_images + categories + taxonomy | Partial | لا Admin Repository أو lifecycle |
| Product pricing | Product UI/read model | metadata `price`, `currency_code` | Read model casts metadata | Demo only | amount/currency CRUD | `product.write` | products contract/metadata | Gap | لا عقد amount/currency صريح |
| Taxonomy | Categories/Search/Filters | `honey_taxonomy`, categories | Production reads موجودة | Demo local taxonomy | canonical reference/selectors | `taxonomy.read/manage` | honey_taxonomy/categories | Partial | Admin source منفصل/مختصر |
| Regions | Search/Store filters | `regions` + local reference JSON | `listRegions` وlocal codes | Demo regions | governorate/district selectors | `taxonomy.read`, `region.manage` | regions | Partial | provenance/sync matrix |
| Banners | Home carousel | `customer_banners` read | Production read موجود | لا توجد، Demo images | upload/order/activate/deactivate/delete | `banner.read/write/publish` | banners + storage | Partial | لا Admin upload/backend |
| Requests | Customer requests | `requests` read | createRequest غير مهيأ | Demo RequestsPanel | assign/read/update/close/reply | `request.read/write` | requests/request_messages | Blocked | no production create/reply |
| Messages | MessagesScreen | conversations/messages empty | list/send غير مهيأ | لا توجد | moderation/response where allowed | `message.read/write` | request_messages/conversations model | Blocked | no repository path |
| Notifications | Account/Notifications | notifications read + mark read | mark read موجود | لا توجد | inspect/notify if required | `notification.read/write` | notifications | Partial | no Admin action model |
| Reviews | Product detail | approved reviews read | createReview غير مهيأ | لا توجد | moderate pending/hidden | `review.read/review.approve/reject` | reviews | Blocked | write/moderation UI absent |
| Comments | Product/review | `listComments` returns empty | createComment غير مهيأ | لا توجد | moderate comments | `comment.read/review` | comments | Blocked | production path absent |
| Favorites/Follows/Likes | Product/store UI | reads/writes partial | toggles return not configured | لا توجد | analytics/moderation only as allowed | `analytics.read` | favorites/store_followers/review_likes/comment_likes | Blocked | interaction writes absent |
| Product views | discovery/detail | `trackProductView` not configured | analytics gateway absent | لا توجد | aggregate views | `analytics.read` | analytics source to be confirmed | Blocked | no event sink/queries |
| Dashboard metrics | Admin overview | Demo array lengths | no Admin repository | Demo metric cards | real aggregate dashboard | `analytics.read` | multiple canonical tables | Blocked | all metrics fake in current Admin |
| Administrators | none | admin_roles/admin_users | DB tables only | none | bootstrap/add/deactivate/assign scope | `admin.manage` | auth.users + users + admin_users + roles | Blocked | no local Auth/admin UI |
| Audit Logs | none | `audit_logs` table/policies | no Admin path | none | read/filter immutable logs | `audit.read` | audit_logs | Partial | no event coverage/UI |
| Storage privacy | none | public/private buckets + policies | DB migration only | none | signed/private access and upload | `storage.public.write`, `verification.read_sensitive` | storage.objects | Partial | policy/route tests absent |
| App settings | Settings screen | local/app settings | no Admin mapping | none | manage only if domain requires | `settings.manage` | to be confirmed | Unknown | no source contract |
