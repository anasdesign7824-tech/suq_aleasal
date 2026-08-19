# Discovery — فجوات مركز التاجر ونموذج المنتج

## مشكلة التبويبات

`MerchantDashboard` يستخدم `DefaultTabController` بستة تبويبات داخل `Column`، لكن `TabBar` يعتمد على `TabBarTheme` عام يضع `labelColor` و`unselectedLabelColor` باللون الكريمي. الخلفية في مركز التاجر كريمية/سطحية، لذلك تختفي النصوص وتظهر مساحة بيضاء كما في الصورة. يجب إعطاء شريط التبويب حاوية وتدرجًا واضحًا، مع ألوان نص متباينة ومؤشر مرئي، وعدم الاعتماد على Theme عام واحد لكل الأسطح.

## فجوة نموذج المنتج

`_showProductEditor` الحالي يحتوي فقط على `name_ar` و`description`، ثم ينشئ `AssalProductDraft` بقيم افتراضية أو قيم المنتج السابق. هذا يعني أن التاجر لا يستطيع إدخال التصنيف، السعر، الوزن، المصدر، الجودة، طريقة المعالجة، التغليف، التوفر، الشحن، نقاط الاستلام، الوسوم، المكونات، تاريخ الإنتاج، تاريخ التعبئة، مدة الصلاحية، الشهادات، أو صور المنتج من الواجهة.

## العقد الفعلية

`AssalProductDraft` الحالي يحتوي على `nameAr`, `nameEn`, `description`, `taxonomyId`, `productType`, `gradeLevel`, `metadata`, و`imageUrls`. جدول Production `products` يحتوي على `name_ar`, `name_en`, `description`, `taxonomy_id`, `product_type`, `grade_level`, `metadata`, و`status`. الحقول التفصيلية التي يعرضها العميل موجودة في `AssalProductSummary` وتُقرأ من `metadata` مثل `price`, `weight_label`, `origin_country`, `province_name_ar`, `honey_identity`, `quality_label_ar`, `processing_method_ar`, `processing_status_ar`, `packaging_label_ar`, `production_date`, `packaged_date`, `shelf_life_label_ar`, `delivery_options`, `pickup_locations`, `tags`, `badges`, `regions`, `forms`, `purpose`, `availability`, `harvest_label`, و`certifications`.

## الإصلاح المطلوب

يُبنى محرر منتج متعدد الأقسام ببيانات حقيقية من `listTaxonomy()` و`listRegions()`: معلومات أساسية، التصنيف، السعر والوزن والتوفر، المصدر والجودة، المعالجة والتغليف، الشحن والاستلام، الوسوم والمكونات والشهادات، ثم معرض الصور المباشر عبر `uploadProductImage`. يجب أن يمرر الحقول إلى `metadata` بصيغة متوافقة مع قارئ `AssalProductSummary`، وأن يحفظ create/update عبر Repository، مع revision للمنتج active كما هو مطبق في ProductionRepository.
