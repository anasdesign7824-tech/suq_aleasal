import 'package:flutter/services.dart';

import 'package:assalkom_data/assal_repository.dart';
import 'assal_assets.dart';

class RootBundleDemoCatalogLoader implements DemoCatalogLoader {
  const RootBundleDemoCatalogLoader();
  @override
  Future<String> loadJson() => rootBundle.loadString(AssalAssets.demoCatalog);
}
