# عسلكم — Design System Contract

## الهوية

يستخدم النظام اسم **عسلكم** في الواجهات، ويحافظ على الاسم الهندسي `Souq Al Assal / سوق العسل` داخل الكود والوثائق. الأسلوب العام **Premium Arabic Social Marketplace**: دافئ، فخم، هادئ، واضح، ومتوازن، مع مساحات بيضاء وبطاقات ناعمة دون ازدحام.

## Color Tokens

| Token | القيمة | الاستخدام |
|---|---:|---|
| `primary` | `#F39C12` | الإجراء الأساسي، الروابط المهمة، مؤشرات التفاعل |
| `primaryDark` | `#9C5A00` | حالة الضغط والتباين الأعلى مع نص أبيض |
| `primaryLight` | `#FFA94D` | إبرازات العسل والتدرجات الخفيفة |
| `secondary` | `#8B5A2B` | العناصر الأرضية الثانوية والتصنيفات |
| `deepBrown` | `#4F2E1F` | النصوص القوية والعناوين الداكنة |
| `honey` | `#F39C12` | الهوية العسلية والوسوم |
| `honeyLight` | `#FFF0D6` | خلفيات لطيفة وشرائح العسل |
| `cream` | `#F8F4EC` | الخلفية الدافئة الأساسية |
| `background` | `#FCFAF7` | خلفية الصفحات |
| `surface` | `#FFFFFF` | البطاقات والحوامل |
| `surfaceVariant` | `#F4EEE5` | الحوامل الثانوية |
| `textPrimary` | `#342118` | النص الأساسي |
| `textSecondary` | `#6F5B4C` | النص الثانوي |
| `textMuted` | `#9A897D` | النص المساعد |
| `border` | `#E8DCCB` | الحدود والفواصل |
| `success` | `#4F7A45` | نجاح متناسق مع الطبيعة |
| `warning` | `#B86B1E` | تنبيه دافئ |
| `error` | `#A64232` | خطأ غير صارخ |
| `info` | `#6B675C` | معلومات محايدة دافئة |

## Typography Tokens

الخط الموحد هو **IBM Plex Sans Arabic**. لا يُستخدم خط مختلف للعناوين أو البطاقات أو الأزرار دون قرار موثق.

| المستوى | الوزن | الحجم | ارتفاع السطر | الاستخدام |
|---|---|---:|---:|---|
| `display` | Bold | 36 | 48 | Hero والعناوين الكبرى |
| `heading1` | Bold | 30 | 40 | عناوين الصفحات |
| `heading2` | SemiBold | 24 | 34 | أقسام رئيسية |
| `heading3` | SemiBold | 20 | 30 | عناوين البطاقات |
| `title` | SemiBold | 18 | 28 | العنوان الدلالي |
| `subtitle` | Medium | 16 | 26 | الوصف القصير |
| `bodyLarge` | Regular | 16 | 28 | النص المهم |
| `body` | Regular | 14 | 24 | النص العام |
| `bodySmall` | Regular | 12 | 20 | النص الثانوي |
| `caption` | Medium | 11 | 18 | بيانات مساعدة |
| `button` | SemiBold | 14 | 22 | الأزرار |
| `label` | Medium | 12 | 18 | الحقول والوسوم |
| `navigation` | SemiBold | 13 | 20 | التنقل |

## Spacing

يستخدم النظام سلمًا من مضاعفات 4: `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `2xl=32`, `3xl=40`, `4xl=48`, `5xl=64`.

## Radius وElevation

| Token | القيمة | الاستخدام |
|---|---:|---|
| `radiusSmall` | 8 | حقول ووسوم صغيرة |
| `radiusMedium` | 12 | أزرار وحقول وبطاقات ثانوية |
| `radiusLarge` | 18 | البطاقات الأساسية |
| `radiusExtraLarge` | 28 | الحوامل واللوحات البارزة |
| `radiusPill` | 999 | Chips وBadges والأزرار الحبوبية |
| `elevationSoft` | `0 8px 24px rgba(79,46,31,.08)` | بطاقات مرفوعة |
| `elevationRaised` | `0 14px 36px rgba(79,46,31,.12)` | حوامل بارزة |

## مكونات العقد

كل مكوّن مشترك يجب أن يدعم RTL، وحالة الضغط أو التركيز، والتباين، وإمكانية الوصول، ولا يحتوي على منطق بيانات مباشر. المكونات الإلزامية هي: `AppBar`, `PrimaryButton`, `SecondaryButton`, `HoneyCard`, `StoreCard`, `ProductCard`, `SearchField`, `FilterChip`, `Badge`, `InputField`, `Dialog`, `LoadingState`, `EmptyState`, و`ErrorState`.

## قواعد الاستخدام

يُمنع hard-coded colors أو radii أو spacing داخل الشاشات. تُستخدم التوكنز ومكونات النظام. حالات التحميل والفراغ والخطأ جزء من العقد وليست إضافات تجميلية. أي حركة يجب أن تكون قصيرة وهادئة، ولا تغيّر layout بطريقة تربك القراءة.
