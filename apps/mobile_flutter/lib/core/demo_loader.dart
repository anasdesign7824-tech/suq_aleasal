import 'package:flutter/services.dart';

import 'package:assalkom_data/assal_repository.dart';

class RootBundleDemoCatalogLoader implements DemoCatalogLoader {
  const RootBundleDemoCatalogLoader();
  @override
  Future<String> loadJson() => rootBundle.loadString('assets/demo_catalog.json');
}
