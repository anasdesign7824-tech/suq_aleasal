import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_design/assal_tokens.dart';

import '../../core/assal_widgets.dart';
import '../customer/customer_catalog.dart';

class MerchantProductEditorScreen extends StatefulWidget {
  const MerchantProductEditorScreen({
    super.key,
    required this.repository,
    required this.storeId,
    this.product,
  });

  final AssalRepository repository;
  final String storeId;
  final AssalProductSummary? product;

  @override
  State<MerchantProductEditorScreen> createState() =>
      _MerchantProductEditorScreenState();
}

class _PendingProductImage {
  const _PendingProductImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

class _MerchantProductEditorScreenState
    extends State<MerchantProductEditorScreen> {
  final formKey = GlobalKey<FormState>();
  late final Future<AssalLoadState<List<AssalTaxonomy>>> taxonomyFuture;
  late final Future<AssalLoadState<List<AssalRegion>>> regionsFuture;

  late final TextEditingController nameArController;
  late final TextEditingController nameEnController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController currencyController;
  late final TextEditingController weightController;
  late final TextEditingController originController;
  late final TextEditingController provinceController;
  late final TextEditingController identityController;
  late final TextEditingController qualityController;
  late final TextEditingController processingMethodController;
  late final TextEditingController processingStatusController;
  late final TextEditingController packagingController;
  late final TextEditingController productionDateController;
  late final TextEditingController packagedDateController;
  late final TextEditingController shelfLifeController;
  late final TextEditingController deliveryController;
  late final TextEditingController pickupController;
  late final TextEditingController purposeController;
  late final TextEditingController availabilityController;
  late final TextEditingController harvestController;
  late final TextEditingController componentsController;
  late final TextEditingController tagsController;
  late final TextEditingController badgesController;
  late final TextEditingController formsController;
  late final TextEditingController certificationsController;

  ProductType productType = ProductType.honey;
  String? taxonomyId;
  String? regionId;
  String? governorateId;
  String? districtId;
  int? gradeLevel;
  final existingImageUrls = <String>[];
  final pendingImages = <_PendingProductImage>[];
  String? persistedProductId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    taxonomyFuture = widget.repository.listTaxonomy();
    regionsFuture = widget.repository.listRegions();
    nameArController = TextEditingController(text: product?.nameAr ?? '');
    nameEnController = TextEditingController(text: product?.nameEn ?? '');
    descriptionController =
        TextEditingController(text: product?.description ?? '');
    priceController = TextEditingController(text: _numberText(product?.price));
    currencyController =
        TextEditingController(text: product?.currencyCode ?? 'YER');
    weightController = TextEditingController(text: product?.weightLabel ?? '');
    originController =
        TextEditingController(text: product?.originCountry ?? 'اليمن');
    provinceController =
        TextEditingController(text: product?.provinceNameAr ?? '');
    identityController =
        TextEditingController(text: product?.honeyIdentity ?? '');
    qualityController =
        TextEditingController(text: product?.qualityLabelAr ?? '');
    processingMethodController =
        TextEditingController(text: product?.processingMethodAr ?? '');
    processingStatusController =
        TextEditingController(text: product?.processingStatusAr ?? '');
    packagingController =
        TextEditingController(text: product?.packagingLabelAr ?? '');
    productionDateController =
        TextEditingController(text: _dateText(product?.productionDate));
    packagedDateController =
        TextEditingController(text: _dateText(product?.packagedDate));
    shelfLifeController =
        TextEditingController(text: product?.shelfLifeLabelAr ?? '');
    deliveryController =
        TextEditingController(text: product?.deliveryOptions.join('، ') ?? '');
    pickupController =
        TextEditingController(text: product?.pickupLocations.join('، ') ?? '');
    purposeController = TextEditingController(text: product?.purpose ?? '');
    availabilityController =
        TextEditingController(text: product?.availability ?? 'متاح للاستفسار');
    harvestController =
        TextEditingController(text: product?.harvestLabel ?? '');
    componentsController =
        TextEditingController(text: product?.components.join('، ') ?? '');
    tagsController =
        TextEditingController(text: product?.tags.join('، ') ?? '');
    badgesController =
        TextEditingController(text: product?.badges.join('، ') ?? '');
    formsController =
        TextEditingController(text: product?.forms.join('، ') ?? '');
    certificationsController = TextEditingController(
      text: product?.certifications.join('، ') ?? '',
    );
    productType = product?.productType ?? ProductType.honey;
    taxonomyId = product?.taxonomyId;
    gradeLevel = product?.gradeLevel;
    existingImageUrls.addAll(product?.imageUrls ?? const <String>[]);
  }

  String _numberText(double? value) => value == null ? '' : '$value';

  String _dateText(DateTime? value) =>
      value == null ? '' : value.toIso8601String().split('T').first;

  @override
  void dispose() {
    for (final controller in [
      nameArController,
      nameEnController,
      descriptionController,
      priceController,
      currencyController,
      weightController,
      originController,
      provinceController,
      identityController,
      qualityController,
      processingMethodController,
      processingStatusController,
      packagingController,
      productionDateController,
      packagedDateController,
      shelfLifeController,
      deliveryController,
      pickupController,
      purposeController,
      availabilityController,
      harvestController,
      componentsController,
      tagsController,
      badgesController,
      formsController,
      certificationsController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> _listValue(String value) => value
      .split(RegExp(r'[,،\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  void _putText(Map<String, Object?> metadata, String key, String value) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) metadata[key] = normalized;
  }

  Map<String, Object?> _metadata() {
    final metadata = <String, Object?>{};
    final price = double.tryParse(priceController.text.trim());
    if (price != null) metadata['price'] = price;
    _putText(metadata, 'currency_code', currencyController.text);
    _putText(metadata, 'weight_label', weightController.text);
    _putText(metadata, 'origin_country', originController.text);
    _putText(metadata, 'province_name_ar', provinceController.text);
    _putText(metadata, 'honey_identity', identityController.text);
    _putText(metadata, 'quality_label_ar', qualityController.text);
    _putText(metadata, 'processing_method_ar', processingMethodController.text);
    _putText(metadata, 'processing_status_ar', processingStatusController.text);
    _putText(metadata, 'packaging_label_ar', packagingController.text);
    _putText(metadata, 'production_date', productionDateController.text);
    _putText(metadata, 'packaged_date', packagedDateController.text);
    _putText(metadata, 'shelf_life_label_ar', shelfLifeController.text);
    _putText(metadata, 'purpose', purposeController.text);
    _putText(metadata, 'availability', availabilityController.text);
    _putText(metadata, 'harvest_label', harvestController.text);
    metadata['delivery_options'] = _listValue(deliveryController.text);
    metadata['pickup_locations'] = _listValue(pickupController.text);
    metadata['components'] = _listValue(componentsController.text);
    metadata['tags'] = _listValue(tagsController.text);
    metadata['badges'] = _listValue(badgesController.text);
    metadata['forms'] = _listValue(formsController.text);
    metadata['certifications'] = _listValue(certificationsController.text);
    if (regionId != null) metadata['region_id'] = regionId;
    return metadata;
  }

  AssalProductDraft _draft() => AssalProductDraft(
        nameAr: nameArController.text.trim(),
        nameEn: nameEnController.text.trim().isEmpty
            ? null
            : nameEnController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        taxonomyId: taxonomyId,
        productType: productType,
        gradeLevel: gradeLevel,
        metadata: _metadata(),
        imageUrls: existingImageUrls,
      );

  String _extension(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  Future<void> _pickImages() async {
    final selected = await ImagePicker().pickMultiImage(
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (selected.isEmpty) return;
    final additions = <_PendingProductImage>[];
    for (final file in selected) {
      additions.add(
        _PendingProductImage(
          bytes: await file.readAsBytes(),
          extension: _extension(file),
        ),
      );
    }
    if (mounted) setState(() => pendingImages.addAll(additions));
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (existingImageUrls.isEmpty && pendingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف صورة واحدة على الأقل قبل حفظ المنتج.')),
      );
      return;
    }
    final session = await widget.repository.getSession();
    if (!mounted) return;
    if (session.isUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.errorMessageAr ?? 'تعذر مزامنة الحساب الآن.')),
      );
      return;
    }
    if (!session.isAuthenticated || session.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول قبل حفظ المنتج.')),
      );
      return;
    }
    setState(() => saving = true);
    final draft = _draft();
    final currentProductId = widget.product?.id ?? persistedProductId;
    final result = currentProductId == null
        ? await widget.repository.createMerchantProduct(
            session.user!.id,
            widget.storeId,
            draft,
          )
        : await widget.repository.updateMerchantProduct(
            session.user!.id,
            currentProductId,
            draft,
          );
    if (!mounted) return;
    if (result is AssalData<AssalProductSummary>) {
      persistedProductId = result.value.id;
      String? imageError;
      final uploadedImageUrls = <String>[];
      final remainingImages = <_PendingProductImage>[];
      for (final image in pendingImages) {
        final uploaded = await widget.repository.uploadProductImage(
          session.user!.id,
          result.value.id,
          image.bytes,
          image.extension,
        );
        if (uploaded is AssalData<String>) {
          uploadedImageUrls.add(uploaded.value);
        } else if (uploaded is AssalError<String>) {
          imageError = uploaded.messageAr;
          remainingImages.add(image);
        }
      }
      existingImageUrls.addAll(uploadedImageUrls);
      pendingImages
        ..clear()
        ..addAll(remainingImages);
      if (!mounted) return;
      setState(() => saving = false);
      final previewProduct = uploadedImageUrls.isEmpty
          ? result.value
          : result.value.copyWith(
              primaryImageUrl: uploadedImageUrls.first,
              imageUrls: [
                ...result.value.imageUrls,
                ...uploadedImageUrls,
              ],
            );
      if (imageError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ المنتج ويمكنك إعادة المحاولة لرفع الصور المتبقية: $imageError',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null && currentProductId == null
              ? 'تم حفظ المنتج كمعلّق.'
              : 'تم حفظ تعديل المنتج وفق حالة النشر.'),
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            repository: widget.repository,
            productId: previewProduct.id,
            initialProduct: previewProduct,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() => saving = false);
      if (result is AssalError<AssalProductSummary>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.messageAr)));
      }
    }
  }

  Widget _sectionTabBar() => Container(
        decoration: BoxDecoration(
          gradient: AssalColors.darkGradient,
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
        child: const TabBar(
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AssalColors.honey,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: 'الأساسي والتصنيف'),
            Tab(text: 'الجودة والمصدر'),
            Tab(text: 'البيع والتوصيل'),
          ],
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      );

  Widget _dateField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        onTap: saving ? null : () => _selectDate(controller),
      );

  Future<void> _selectDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: initial,
      helpText: 'اختر التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (picked == null || !mounted) return;
    controller.text = picked.toIso8601String().split('T').first;
  }

  Widget _imageSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('صور المنتج', style: AssalTypography.subtitle),
          const SizedBox(height: AssalSpacing.sm),
          if (existingImageUrls.isEmpty && pendingImages.isEmpty)
            const AssalMessageCard(
              icon: Icons.photo_library_outlined,
              message:
                  'أضف صورًا واضحة للمنتج. الصورة الأولى تظهر كصورة أساسية.',
            )
          else
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: existingImageUrls.length + pendingImages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AssalSpacing.sm),
                itemBuilder: (_, index) {
                  if (index < existingImageUrls.length) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AssalRadius.medium),
                      child: Image.network(
                        existingImageUrls[index],
                        width: 142,
                        height: 116,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  final image = pendingImages[index - existingImageUrls.length];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AssalRadius.medium),
                    child: Image.memory(
                      image.bytes,
                      width: 142,
                      height: 116,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AssalSpacing.sm),
          OutlinedButton.icon(
            onPressed: saving ? null : _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('إضافة صور من الجهاز'),
          ),
        ],
      );

  Widget _basicTab() => ListView(
        padding: const EdgeInsets.only(top: AssalSpacing.lg),
        children: [
          _imageSection(),
          const SizedBox(height: AssalSpacing.lg),
          _field(
            nameArController,
            'اسم المنتج بالعربية',
            validator: (value) => value == null || value.trim().length < 2
                ? 'اكتب اسم المنتج.'
                : null,
          ),
          const SizedBox(height: AssalSpacing.md),
          _field(nameEnController, 'اسم المنتج بالإنجليزية (اختياري)'),
          const SizedBox(height: AssalSpacing.md),
          _field(descriptionController, 'وصف المنتج', maxLines: 4),
          const SizedBox(height: AssalSpacing.md),
          FutureBuilder<AssalLoadState<List<AssalTaxonomy>>>(
            future: taxonomyFuture,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final values = state is AssalData<List<AssalTaxonomy>>
                  ? state.value
                  : const <AssalTaxonomy>[];
              return DropdownButtonFormField<String>(
                initialValue: values.any((item) => item.id == taxonomyId)
                    ? taxonomyId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'تصنيف العسل أو المنتج',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: values
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.nameAr),
                      ),
                    )
                    .toList(growable: false),
                validator: (value) => value == null || value.isEmpty
                    ? 'اختر تصنيف المنتج.'
                    : null,
                onChanged: saving
                    ? null
                    : (value) => setState(() => taxonomyId = value),
                hint: const Text('اختر التصنيف من البيانات المعتمدة'),
              );
            },
          ),
          const SizedBox(height: AssalSpacing.md),
          DropdownButtonFormField<ProductType>(
            initialValue: productType,
            decoration: const InputDecoration(
              labelText: 'نوع المنتج',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: ProductType.honey,
                child: Text('عسل'),
              ),
              DropdownMenuItem(
                value: ProductType.wax,
                child: Text('شمع'),
              ),
              DropdownMenuItem(
                value: ProductType.mix,
                child: Text('خلطات نحلية'),
              ),
              DropdownMenuItem(
                value: ProductType.raw,
                child: Text('منتج خام'),
              ),
              DropdownMenuItem(
                value: ProductType.gift,
                child: Text('هدايا ومنتجات جاهزة'),
              ),
            ],
            onChanged: saving
                ? null
                : (value) => setState(() => productType = value ?? productType),
          ),
        ],
      );

  Widget _qualityTab() => ListView(
        padding: const EdgeInsets.only(top: AssalSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _field(
                  priceController,
                  'السعر',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '');
                    return price == null || price < 0
                        ? 'اكتب سعرًا صحيحًا.'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: AssalSpacing.sm),
              SizedBox(
                width: 104,
                child: DropdownButtonFormField<String>(
                  initialValue: const ['YER', 'SAR', 'USD']
                          .contains(currencyController.text)
                      ? currencyController.text
                      : 'YER',
                  decoration: const InputDecoration(labelText: 'العملة'),
                  items: const [
                    DropdownMenuItem(value: 'YER', child: Text('ريال يمني')),
                    DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي')),
                    DropdownMenuItem(value: 'USD', child: Text('دولار')),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => currencyController.text = value ?? 'YER',
                ),
              ),
            ],
          ),
          const SizedBox(height: AssalSpacing.md),
          Row(
            children: [
              Expanded(
                child: _field(
                  weightController,
                  'الوزن أو الحجم',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الوزن أو الحجم.'
                      : null,
                ),
              ),
              const SizedBox(width: AssalSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: gradeLevel,
                  decoration: const InputDecoration(labelText: 'درجة الجودة'),
                  items: [
                    for (var level = 1; level <= 5; level++)
                      DropdownMenuItem(
                        value: level,
                        child: Text('درجة $level'),
                      ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) => setState(() => gradeLevel = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AssalSpacing.md),
          _field(
            originController,
            'بلد المصدر',
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل بلد المصدر.'
                : null,
          ),
          const SizedBox(height: AssalSpacing.md),
          FutureBuilder<AssalLoadState<List<AssalRegion>>>(
            future: regionsFuture,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final values = state is AssalData<List<AssalRegion>>
                  ? state.value
                  : const <AssalRegion>[];
              AssalRegion? selectedRegion;
              for (final item in values) {
                if (item.id == regionId) {
                  selectedRegion = item;
                  break;
                }
              }
              final selectedGovernorateId = governorateId ??
                  selectedRegion?.parentRegionId ?? selectedRegion?.id;
              final selectedDistrictId = districtId ??
                  (selectedRegion?.parentRegionId == null
                      ? null
                      : selectedRegion?.id);
              final governorates = values
                  .where((item) => item.parentRegionId == null)
                  .toList(growable: false);
              final districts = values
                  .where((item) => item.parentRegionId == selectedGovernorateId)
                  .toList(growable: false);
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: governorates.any(
                            (item) => item.id == selectedGovernorateId)
                        ? selectedGovernorateId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'محافظة الإنتاج',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: governorates
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.nameAr),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: saving
                        ? null
                        : (value) => setState(() {
                              governorateId = value;
                              districtId = null;
                              regionId = value;
                              for (final item in governorates) {
                                if (item.id == value) {
                                  provinceController.text = item.nameAr;
                                  break;
                                }
                              }
                            }),
                    hint: const Text('اختر المحافظة من البيانات المعتمدة'),
                  ),
                  const SizedBox(height: AssalSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: districts.any(
                            (item) => item.id == selectedDistrictId)
                        ? selectedDistrictId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'مديرية الإنتاج',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: districts
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.nameAr),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: saving || selectedGovernorateId == null
                        ? null
                        : (value) => setState(() {
                              districtId = value;
                              regionId = value ?? selectedGovernorateId;
                              for (final item in districts) {
                                if (item.id == value) {
                                  provinceController.text = item.nameAr;
                                  break;
                                }
                              }
                            }),
                    hint: const Text('اختر المديرية أو اتركها على مستوى المحافظة'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AssalSpacing.md),
          _field(provinceController, 'وصف المصدر المحلي (اختياري)'),
          const SizedBox(height: AssalSpacing.md),
          _field(identityController, 'هوية العسل أو السلالة'),
          const SizedBox(height: AssalSpacing.md),
          _field(qualityController, 'وصف الجودة أو التوثيق'),
          const SizedBox(height: AssalSpacing.md),
          _field(harvestController, 'موسم أو تاريخ الحصاد'),
          const SizedBox(height: AssalSpacing.md),
          _field(processingMethodController, 'طريقة المعالجة'),
          const SizedBox(height: AssalSpacing.md),
          _field(processingStatusController, 'حالة المعالجة'),
          const SizedBox(height: AssalSpacing.md),
          _field(packagingController, 'نوع التغليف'),
          const SizedBox(height: AssalSpacing.md),
          _dateField(productionDateController, 'تاريخ الإنتاج'),
          const SizedBox(height: AssalSpacing.md),
          _dateField(packagedDateController, 'تاريخ التعبئة'),
          const SizedBox(height: AssalSpacing.md),
          _field(shelfLifeController, 'مدة الصلاحية'),
          const SizedBox(height: AssalSpacing.md),
          _field(componentsController, 'المكونات — افصل بينها بفاصلة'),
          const SizedBox(height: AssalSpacing.md),
          _field(certificationsController, 'الشهادات — افصل بينها بفاصلة'),
        ],
      );

  Widget _salesTab() => ListView(
        padding: const EdgeInsets.only(top: AssalSpacing.lg),
        children: [
          DropdownButtonFormField<String>(
            initialValue: const [
              'متاح للاستفسار',
              'متاح للطلب',
              'غير متاح مؤقتًا',
              'نفد المخزون',
            ].contains(availabilityController.text)
                ? availabilityController.text
                : 'متاح للاستفسار',
            decoration: const InputDecoration(
              labelText: 'حالة التوفر',
              prefixIcon: Icon(Icons.inventory_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'متاح للاستفسار', child: Text('متاح للاستفسار')),
              DropdownMenuItem(value: 'متاح للطلب', child: Text('متاح للطلب')),
              DropdownMenuItem(value: 'غير متاح مؤقتًا', child: Text('غير متاح مؤقتًا')),
              DropdownMenuItem(value: 'نفد المخزون', child: Text('نفد المخزون')),
            ],
            onChanged: saving
                ? null
                : (value) => availabilityController.text = value ?? 'متاح للاستفسار',
          ),
          const SizedBox(height: AssalSpacing.md),
          _field(purposeController, 'الاستخدام أو الغرض'),
          const SizedBox(height: AssalSpacing.md),
          _field(deliveryController, 'خيارات التوصيل — افصل بينها بفاصلة',
              maxLines: 3),
          const SizedBox(height: AssalSpacing.md),
          _field(pickupController, 'نقاط الاستلام — افصل بينها بفاصلة',
              maxLines: 3),
          const SizedBox(height: AssalSpacing.md),
          _field(formsController, 'الأشكال أو العبوات — افصل بينها بفاصلة'),
          const SizedBox(height: AssalSpacing.md),
          _field(tagsController, 'الوسوم — افصل بينها بفاصلة'),
          const SizedBox(height: AssalSpacing.md),
          const AssalMessageCard(
            icon: Icons.verified_outlined,
            message: 'الشارات والتوثيق Pro تُدار من الإدارة بعد المراجعة، ولا يضيفها التاجر يدويًا.',
          ),
          const SizedBox(height: AssalSpacing.lg),
          const AssalMessageCard(
            icon: Icons.preview_outlined,
            message:
                'بعد الحفظ تُرسل هذه البيانات إلى نفس عقد المنتج الذي يقرأه عرض العميل. المنتج الجديد يبقى معلّقًا حتى التفعيل.',
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AssalAppBar(
          title: widget.product == null ? 'إضافة منتج' : 'تعديل المنتج',
        ),
        body: Form(
          key: formKey,
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AssalSpacing.lg,
                    AssalSpacing.lg,
                    AssalSpacing.lg,
                    AssalSpacing.sm,
                  ),
                  child: _sectionTabBar(),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AssalSpacing.lg,
                        ),
                        child: _basicTab(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AssalSpacing.lg,
                        ),
                        child: _qualityTab(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AssalSpacing.lg,
                        ),
                        child: _salesTab(),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AssalSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving ? null : _save,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          saving ? 'جارٍ حفظ المنتج...' : 'حفظ المنتج ومعاينته',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
