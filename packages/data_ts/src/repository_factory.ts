import type { DemoCatalog } from "./demo_repository";
import { DemoRepository } from "./demo_repository";
import { ProductionRepository } from "./production_repository";
import type { AssalDataSourceMode, AssalRepository, ProductionSelectGateway } from "./repository";

export function createAssalRepository(options: {
  mode: AssalDataSourceMode;
  demoCatalog: DemoCatalog;
  productionGateway?: ProductionSelectGateway;
}): AssalRepository {
  if (options.mode === "demo") return new DemoRepository(options.demoCatalog);
  if (!options.productionGateway) throw new Error("Production repository requires an explicit Supabase gateway configuration.");
  return new ProductionRepository(options.productionGateway);
}
