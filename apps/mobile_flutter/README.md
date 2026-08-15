# عسلكم — Mobile Flutter

المشروع الجوال الرسمي لتجربة **عسلكم**، والاسم الهندسي الداخلي للمسار هو `mobile_flutter` ضمن `Souq Al Assal`.

## قواعد البناء

يُبنى التطبيق بـ Flutter/Dart، عربي أولًا وRTL، وبمعمارية Feature-First تفصل Presentation وDomain وData. يبدأ التطبيق بـ Demo Repository وDemo Data ولا يتطلب Supabase لتشغيل Demo Mode.

## المسار المعتمد

```text
UI → ViewModel / Controller → Use Case → Repository Interface
→ Demo Repository → Demo Data + Demo State
```

سيُضاف Supabase Repository لاحقًا خلف العقد نفسه في مرحلة Production Data Sources. لا تتصل أي Widget مباشرة بمصدر بيانات.

## بنية Phase 1

تم تثبيت مجلدات `lib/core` للطبقات المشتركة ومجلد `lib/features` للميزات المستقبلية. لا تُعتبر هذه المجلدات ميزات مكتملة، ولا يجوز الانتقال إلى اعتبار أي Feature مكتملة قبل متطلبات Evidence الواردة في وثائق المشروع.
