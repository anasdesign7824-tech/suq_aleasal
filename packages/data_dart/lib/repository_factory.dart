import 'assal_repository.dart';
import 'demo_repository.dart';
import 'production_repository.dart';

class AssalRepositoryFactory {
  const AssalRepositoryFactory();

  AssalRepository create({
    required AssalDataSourceMode mode,
    required DemoCatalogLoader demoLoader,
    ProductionQueryGateway? productionGateway,
  }) {
    switch (mode) {
      case AssalDataSourceMode.demo:
        return DemoRepository(loader: demoLoader);
      case AssalDataSourceMode.production:
        final gateway = productionGateway;
        if (gateway == null) throw const ProductionRepositoryNotConfigured();
        return ProductionRepository(gateway: gateway);
    }
  }
}
