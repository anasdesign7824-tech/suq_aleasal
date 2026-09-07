# UI DATA GAP REGISTER — عسلكم

> هذه القائمة خاصّة بـ **فجوات البيانات التي تحتاجها الواجهة ولا توجد في العقود/المصادر الحالية**.
> القاعدة: لا تخترع بيانات. اكتب `UI_DATA_GAP` لكل حالة.
> عمود `Backend change?` يوضح ما إذا كان إغلاق الفجوة يتطلب تغيير Backend؛ **لا يتم ضمن هذه المهمة**.

| ID | المطلوب | لماذا تحتاجه الواجهة | أين يجب أن يأتي | هل يوجد بديل حالي | هل يتطلب Backend change? | Status |
|---|---|---|---|---|---|---|
| DG-01 | علاقة متابعة **مستخدم→مستخدم** (Following People) | صفحة Following المطلوبة تميّز الأشخاص عن المتاجر | repository `toggleFollow` / جديد + schema | يتوفر فقط `toggleFollow(userId, storeId)` | Yes (relation/schema) | `UI_DATA_GAP` |
| DG-02 | Order تقليدي كامل (عقد + حالات + سلسلة دفع) | طلب تجاري حقيقي بدل "طلب تواصل" | `AssalRequestSummary` لا تعادل Order | يمكن فقط عرض Request/Contact | Yes | `UI_DATA_GAP` + `BACKEND_GAP` |
| DG-03 | Typed notification destination | الإشعارات يجب أن توجه إلى وجهة قابلة للتنفيذ | `AssalNotificationSummary.payload` map | يظهر `payload` غير typed | Probably yes | `UI_DATA_GAP` |
| DG-04 | Product/Request context داخل المحادثة | رأس المحادثة يجب أن يظهر السياق | `AssalConversationSummary` | storeName فقط | Yes | `UI_DATA_GAP` |
| DG-05 | Policy عرض البريد/الهاتف للملف العام | يمنع كشف بيانات حساسة | User/profile contract + visibility | لا policy adapter | Probably yes | `UI_DATA_GAP` |
| DG-06 | تفضيلات مستخدم persistent (إشعارات/لغة/مظهر) | الإعدادات يجب أن تبقى بين الجلسات | repository preference ops | local toggle فقط | Yes | `UI_DATA_GAP` |
| DG-07 | مؤشرات تحليلات كاملة للتاجر | لوحة إحصاءات دقيقة | analytics events/aggregates | some counters (views, followers, reviews) | Yes | `UI_DATA_GAP` |
| DG-08 | Governorate/District في Profile | بديل موحد لموقع نص حر | Profile patch location fields | locationLabel free text | Probably yes | `UI_DATA_GAP` |
| DG-09 | عدد منتجات المتجر في StoreCard | بطاقة متجر بسيطة تعرض products count | Store summary | لا يوجد | Yes (or derived local only) | `UI_DATA_GAP` |
| DG-10 | حالة علاقة الحفظ/المتابعة في بطاقات كيان | إظهار حالة "محفوظ/تتابع" بشكل صحيح | product/store summaries + relation state | تعتمد على التحميل المنفصل | Partial | `UI_DATA_GAP` |
| DG-11 | Badge/quality reference المبطنة في عرض المنتج | عرض الشارات بالمعنى وليس قيم خام | taxonomy JSON / badges mapping | raw `badges` strings موجودة | No | `UI_DATA_GAP` |
| DG-12 | حالة partial/unauthorized/forbidden/offline على المستوى العام | سلوك موحد للشاشات | repository error codes + session | `AssalLoadState` محدود | Partial | `UI_DATA_GAP` |
