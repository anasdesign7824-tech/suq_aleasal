# عسلكم — Design System Implementation Contract

## الهوية المرئية

يعتمد Customer Web/APK على هوية عربية دافئة وفخمة وهادئة. مصدر الخط الرسمي هو **IBM Plex Sans Arabic** الموجود داخل المشروع، ومصدر الهوية الشعاراتية هو `logo-internal.svg` و`logo-external.svg`. لا تستخدم الواجهات خطًا بديلًا أو شعارًا مرسومًا يدويًا.

## Typography

يعلن التطبيق الأوزان السبعة الموجودة في المشروع: Thin 100، ExtraLight 200، Light 300، Regular 400، Medium 500، SemiBold 600، وBold 700. المستوى البصري يمر عبر `display`, `heading1`, `heading2`, `heading3`, `title`, `subtitle`, `bodyLarge`, `body`, `bodySmall`, `caption`, `button`, `label`, و`navigation`. أي شاشة جديدة تستخدم `AssalTypography` ولا تضع `fontSize` أو `fontFamily` عشوائيًا.

## Tokens

| المجموعة | العقد |
|---|---|
| Colors | primary, primaryDark, primaryLight, secondary, honey, honeyLight, cream, background, surface, surfaceVariant, textPrimary, textSecondary, textMuted, border, success, warning, error, info |
| Spacing | xs 4، sm 8، md 12، lg 16، xl 24، x2l 32، x3l 40، x4l 48، x5l 64 |
| Radius | small 8، medium 12، large 18، extraLarge 28، pill 999 |
| Assets | `AssalAssets.logoInternal`, `AssalAssets.logoExternal`, `AssalAssets.demoCatalog`, `AssalAssets.fontFamily` |

## Components

المكونات المشتركة الحالية هي `AssalBrandMark`, `DemoModePill`, `AssalStateView`, `AssalMessageCard`, `SectionHeader`, `AssalImageTile`, `ProductCard`, `StoreCard`, `RatingStars`, و`InfoChip`. يجب أن تدعم RTL، touch/focus states، semantics، وتفشل بصريًا بوضوح عند غياب الصورة بدل إظهار صورة مكسورة أو إطار أحمر.

## RTL وLocalization

الجذر هو `MaterialApp` بلغة عربية و`GlobalMaterialLocalizations.delegates` مع `Directionality` RTL. هذا شرط runtime حقيقي لأن `RefreshIndicator` و`NavigationBar` يعتمدان على MaterialLocalizations. يجب إعادة إثباته في widget test وعلى APK مثبت، لا بالتحليل الساكن فقط.

## Asset rules

تسجل `AssalAssets` المسارات القابلة للاستخدام حتى لا تتكرر strings داخل features. يسجل `pubspec.yaml` ملفات SVG وDemo JSON ومجلد الخطوط. الأصول المرجعية داخل `assets/identity-reference` للاختبار البصري فقط، وليست صور منتجات عشوائية. صور المنتجات والمتاجر يجب أن تكون 1:1 أو fallback دافئًا وصادقًا، بينما الغلاف wide والمعرض متعدد الصور عندما يتوفران في البيانات.

## Acceptance

يُرفض أي مكوّن يستخدم لونًا أو radius أو خطًا صلبًا بلا مبرر، أو يخلط هوية Material الافتراضية بالهوية العسلية، أو يترك زرًا بلا فعل، أو يسبب overflow/contrast/RTL failure على Web أو APK.
