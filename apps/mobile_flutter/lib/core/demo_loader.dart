import 'package:flutter/services.dart';

import '../../../../packages/data_dart/lib/assal_repository.dart';

class RootBundleDemoCatalogLoader implements DemoCatalogLoader {
  const RootBundleDemoCatalogLoader();

  @override
  Future<String> loadJson() => rootBundle.loadString('assets/demo_catalog.json');
}
