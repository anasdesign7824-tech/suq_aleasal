import { useMemo, useState } from "react";
import {
  Box,
  Database,
  Eraser,
  Hexagon,
  Layers3,
  RotateCcw,
  Search,
  Store,
  Trash2,
  Users,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { demoCatalog } from "@/data/demoCatalog";

/**
 * Design-only local preview data manager.
 *
 * IMPORTANT:
 * - This panel only edits a LOCAL in-memory copy of the demo catalog used for
 *   UI/design verification. It never touches Supabase, the database, RLS,
 *   schema, auth, or any production endpoint.
 * - Every control supports filtering, editing, deleting, or resetting these
 *   temporary design records so the UI can be tested with sample data then
 *   restored to the original demo catalog.
 */

type MutableProduct = {
  id: string;
  store_id: string;
  category_name_ar: string;
  subcategory_name_ar?: string | null;
  name_ar: string;
  product_type: string;
  status: string;
  is_featured: boolean;
  primary_image_url?: string | null;
};

type MutableStore = {
  id: string;
  name_ar: string;
  region_id?: string | null;
  is_verified: boolean;
  status: string;
};

export function AdminDesignPreviewPanel() {
  const [products, setProducts] = useState<MutableProduct[]>(() =>
    demoCatalog.products.map((item) => ({
      id: item.id,
      store_id: item.store_id,
      category_name_ar: item.category_name_ar,
      subcategory_name_ar: item.subcategory_name_ar ?? null,
      name_ar: item.name_ar,
      product_type: item.product_type,
      status: item.status ?? "draft",
      is_featured: item.is_featured ?? false,
      primary_image_url: item.primary_image_url ?? null,
    })),
  );
  const [stores, setStores] = useState<MutableStore[]>(() =>
    demoCatalog.stores.map((item) => ({
      id: item.id,
      name_ar: item.name_ar,
      region_id: item.region_id ?? null,
      is_verified: item.is_verified ?? false,
      status: item.status ?? "open",
    })),
  );
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("");
  const [statusFilter, setStatusFilter] = useState("");

  const originalProducts = useMemo(
    () =>
      demoCatalog.products.map((item) => ({
        id: item.id,
        store_id: item.store_id,
        category_name_ar: item.category_name_ar,
        subcategory_name_ar: item.subcategory_name_ar ?? null,
        name_ar: item.name_ar,
        product_type: item.product_type,
        status: item.status ?? "draft",
        is_featured: item.is_featured ?? false,
        primary_image_url: item.primary_image_url ?? null,
      })),
    [],
  );
  const originalStores = useMemo(
    () =>
      demoCatalog.stores.map((item) => ({
        id: item.id,
        name_ar: item.name_ar,
        region_id: item.region_id ?? null,
        is_verified: item.is_verified ?? false,
        status: item.status ?? "open",
      })),
    [],
  );

  const filteredProducts = products.filter((item) => {
    const text = query.trim().toLowerCase();
    const matchesText =
      text.length === 0 ||
      item.name_ar.toLowerCase().includes(text) ||
      item.category_name_ar.toLowerCase().includes(text) ||
      item.id.toLowerCase().includes(text);
    const matchesType = typeFilter === "" || item.product_type === typeFilter;
    const matchesStatus =
      statusFilter === "" || item.status === statusFilter;
    return matchesText && matchesType && matchesStatus;
  });

  const types = useMemo(
    () => Array.from(new Set(products.map((item) => item.product_type))).sort(),
    [products],
  );
  const statuses = useMemo(
    () => Array.from(new Set(products.map((item) => item.status))).sort(),
    [products],
  );

  const updateProduct = (id: string, patch: Partial<MutableProduct>) =>
    setProducts((current) =>
      current.map((item) => (item.id === id ? { ...item, ...patch } : item)),
    );

  const deleteProduct = (id: string) =>
    setProducts((current) => current.filter((item) => item.id !== id));

  const deleteStore = (id: string) =>
    setStores((current) => current.filter((item) => item.id !== id));

  const resetAll = () => {
    setProducts(originalProducts);
    setStores(originalStores);
  };

  const destroyAll = () => {
    setProducts([]);
    setStores([]);
  };

  const counts = {
    products: products.length,
    stores: stores.length,
    reviews: demoCatalog.reviews?.length ?? 0,
    requests: demoCatalog.requests?.length ?? 0,
    notifications: demoCatalog.notifications?.length ?? 0,
  };

  return (
    <div className="space-y-6">
      <section className="admin-card p-6">
        <div className="flex items-start gap-3">
          <div className="grid size-11 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]">
            <Database className="size-5" />
          </div>
          <div className="min-w-0">
            <p className="section-kicker">أداة معاينة التصميم فقط</p>
            <h2 className="mt-1 text-xl font-bold text-[#342118]">
              بيانات عسلكم التجريبية
            </h2>
            <p className="mt-2 text-sm leading-7 text-[#806b5a]">
              هذه السجلات تُستخدم محليًا للتأكد من شكل الواجهة والترتيب والبيانات.
              التعديل والحذف هنا <strong>لا يكتب في Supabase</strong> ولا يغيّر قاعدة
              البيانات أو RLS أو Schema. زر «استعادة النسخة الأصلية» يعيد كل شيء.
            </p>
          </div>
        </div>
        <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
          <MiniStat icon={Box} label="منتجات" value={counts.products} />
          <MiniStat icon={Store} label="متاجر" value={counts.stores} />
          <MiniStat icon={Layers3} label="مراجعات" value={counts.reviews} />
          <MiniStat icon={Users} label="طلبات" value={counts.requests} />
          <MiniStat icon={Hexagon} label="إشعارات" value={counts.notifications} />
        </div>
        <div className="mt-5 flex flex-wrap items-center gap-3 rounded-2xl border border-amber-200 bg-amber-50/60 px-4 py-3 text-sm text-amber-900">
          <Eraser className="size-4" />
          <span className="font-bold">وضع تجريبي آمن:</span>
          <span>يمكن التصفية والتعديل والحذف ثم الاستعادة بنقرة واحدة.</span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              if (window.confirm("محو كل عينات التصميم المحلية؟")) destroyAll();
            }}
            className="mr-auto border-red-200 text-red-800"
          >
            <Trash2 className="ml-2 size-4" />
            محو الكل
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={resetAll}
            className="border-amber-300 text-amber-900"
          >
            <RotateCcw className="ml-2 size-4" />
            استعادة النسخة الأصلية
          </Button>
        </div>
      </section>

      <section className="admin-card overflow-hidden">
        <div className="border-b border-[#eee1d0] px-5 py-5">
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <h3 className="text-xl font-bold text-[#342118]">
                منتجات التصميم التجريبية
              </h3>
              <p className="mt-1 text-sm text-[#806b5a]">
                فلترة وتحرير وحذف سجلات العرض فقط.
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              <div className="relative">
                <Search className="absolute right-3 top-1/2 size-4 -translate-y-1/2 text-[#9a897d]" />
                <Input
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  className="h-10 w-full rounded-xl border-[#eadcc9] pr-9 sm:w-56"
                  placeholder="ابحث في عينات التصميم"
                />
              </div>
              <select
                value={typeFilter}
                onChange={(event) => setTypeFilter(event.target.value)}
                className="h-10 rounded-xl border border-[#eadcc9] bg-white px-3 text-sm"
              >
                <option value="">كل الأنواع</option>
                {types.map((type) => (
                  <option key={type} value={type}>
                    {type}
                  </option>
                ))}
              </select>
              <select
                value={statusFilter}
                onChange={(event) => setStatusFilter(event.target.value)}
                className="h-10 rounded-xl border border-[#eadcc9] bg-white px-3 text-sm"
              >
                <option value="">كل الحالات</option>
                {statuses.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
        <FilteredProductsTable
          products={filteredProducts}
          stores={stores}
          onUpdate={updateProduct}
          onDelete={deleteProduct}
        />
      </section>

      <section className="admin-card overflow-hidden">
        <div className="border-b border-[#eee1d0] px-5 py-5">
          <div className="flex items-center justify-between gap-3">
            <div>
              <h3 className="text-xl font-bold text-[#342118]">
                متاجر التصميم التجريبية
              </h3>
              <p className="mt-1 text-sm text-[#806b5a]">
                حذف متجر من عينات العرض لا يؤثر على الإنتاج.
              </p>
            </div>
            <Badge variant="outline" className="border-[#e3c28d] text-[#8b5a2b]">
              {stores.length} متجر
            </Badge>
          </div>
        </div>
        <div className="divide-y divide-[#f1e7da]">
          {stores.map((store) => (
            <div
              key={store.id}
              className="flex flex-wrap items-center justify-between gap-3 px-5 py-4"
            >
              <div className="min-w-0">
                <p className="font-semibold text-[#432a1e]">{store.name_ar}</p>
                <p className="mt-1 text-xs text-[#806b5a]" dir="ltr">
                  {store.id} · {store.region_id ?? "بدون منطقة"}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <Badge variant={store.is_verified ? "default" : "outline"}>
                  {store.is_verified ? "موثق" : "غير موثق"}
                </Badge>
                <Button
                  variant="ghost"
                  size="icon"
                  className="text-red-800"
                  onClick={() => deleteStore(store.id)}
                  aria-label={`حذف ${store.name_ar}`}
                >
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </div>
          ))}
          {stores.length === 0 && (
            <div className="px-5 py-10 text-center text-sm text-[#806b5a]">
              لا توجد متاجر تجريبية متبقية. اضغط «استعادة النسخة الأصلية».
            </div>
          )}
        </div>
      </section>
    </div>
  );
}

function FilteredProductsTable({
  products,
  stores,
  onUpdate,
  onDelete,
}: {
  products: MutableProduct[];
  stores: MutableStore[];
  onUpdate: (id: string, patch: Partial<MutableProduct>) => void;
  onDelete: (id: string) => void;
}) {
  return (
    <div className="overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow className="border-[#eee1d0] hover:bg-transparent">
            <TableHead className="text-right text-[#806755]">المنتج</TableHead>
            <TableHead className="text-right text-[#806755]">المتجر</TableHead>
            <TableHead className="text-right text-[#806755]">النوع</TableHead>
            <TableHead className="text-right text-[#806755]">الحالة</TableHead>
            <TableHead className="text-left text-[#806755]">إجراء</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product) => {
            const store = stores.find((item) => item.id === product.store_id);
            return (
              <TableRow key={product.id} className="border-[#f2e8dc]">
                <TableCell className="min-w-56 py-4">
                  <div className="flex items-center gap-3">
                    <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-[#fff0d6] text-[#9c5a00]">
                      <Hexagon className="size-4" />
                    </div>
                    <div className="min-w-0">
                      <Input
                        value={product.name_ar}
                        onChange={(event) =>
                          onUpdate(product.id, { name_ar: event.target.value })
                        }
                        className="h-9 rounded-lg border-[#eadcc9] text-sm"
                        aria-label={`اسم ${product.name_ar}`}
                      />
                      <p className="mt-1 truncate text-xs text-[#806b5a]">
                        {product.subcategory_name_ar ?? product.category_name_ar}
                      </p>
                    </div>
                  </div>
                </TableCell>
                <TableCell className="text-sm text-[#705a49]">
                  {store?.name_ar ?? product.store_id}
                </TableCell>
                <TableCell className="text-sm text-[#705a49]">
                  {product.product_type}
                </TableCell>
                <TableCell>
                  <select
                    value={product.status}
                    onChange={(event) =>
                      onUpdate(product.id, { status: event.target.value })
                    }
                    className="h-9 rounded-lg border border-[#eadcc9] bg-white px-2 text-xs"
                  >
                    {["draft", "active", "pending", "paused", "rejected"].map(
                      (status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ),
                    )}
                  </select>
                </TableCell>
                <TableCell className="text-left">
                  <div className="flex items-center justify-end gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="text-red-800"
                      onClick={() => onDelete(product.id)}
                      aria-label={`حذف ${product.name_ar}`}
                    >
                      <Trash2 className="size-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            );
          })}
          {products.length === 0 && (
            <TableRow>
              <TableCell
                colSpan={5}
                className="px-5 py-10 text-center text-sm text-[#806b5a]"
              >
                لا توجد عناصر مطابقة للفلترة الحالية.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}

function MiniStat({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Box;
  label: string;
  value: number;
}) {
  return (
    <div className="rounded-2xl border border-[#eadcc9] bg-[#fffaf3] p-4">
      <div className="flex items-center gap-2 text-[#9c5a00]">
        <Icon className="size-4" />
        <span className="text-xs font-bold">{label}</span>
      </div>
      <p className="mt-2 text-2xl font-bold text-[#342118]" dir="ltr">
        {value}
      </p>
    </div>
  );
}
