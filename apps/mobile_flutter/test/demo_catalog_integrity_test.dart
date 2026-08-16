import 'package:flutter_test/flutter_test.dart';
import 'package:assalkom_contracts/assal_domain.dart';
import 'package:assalkom_data/assal_repository.dart';
import 'package:assalkom_data/demo_repository.dart';
import '../lib/core/demo_loader.dart';

void main() {
  test('real demo catalog has rich linked discovery data', () async {
    final repository = DemoRepository(loader: const RootBundleDemoCatalogLoader());
    final regions = await repository.listRegions();
    final stores = await repository.listStores();
    final products = await repository.listProducts();
    final taxonomy = await repository.listTaxonomy();
    final banners = await repository.listBanners();
    final searches = await repository.listPopularSearches();

    expect((regions as AssalData<List<AssalRegion>>).value.length, greaterThanOrEqualTo(10));
    final storeValues = (stores as AssalData<List<AssalStoreSummary>>).value;
    expect(storeValues.length, greaterThanOrEqualTo(10));
    final productValues = (products as AssalData<List<AssalProductSummary>>).value;
    final storeIds = storeValues.map((store) => store.id).toSet();
    expect(productValues.length, greaterThanOrEqualTo(40));
    expect(productValues.every((product) => storeIds.contains(product.storeId)), isTrue);
    expect((taxonomy as AssalData<List<AssalTaxonomy>>).value.length, greaterThanOrEqualTo(10));
    expect((banners as AssalData<List<AssalBannerSummary>>).value.length, 5);
    expect((searches as AssalData<List<String>>).value.length, greaterThanOrEqualTo(10));
  });
}
