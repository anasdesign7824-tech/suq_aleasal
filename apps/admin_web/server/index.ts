import express, { type ErrorRequestHandler, type Request, type Response } from "express";
import { createServer } from "http";
import path from "path";
import { fileURLToPath } from "url";
import {
  changeAdminPassword,
  clearAdminCookies,
  getAdminSession,
  getRequestAdminSession,
  requireAdmin,
  setAdminCookies,
  type AdminPermission,
} from "./admin-auth";
import {
  answerRequest,
  createAdminIdentity,
  createBanner,
  createProduct,
  deleteBanner,
  deleteProduct,
  deleteStore,
  deleteUser,
  uploadPublicImage,
  getDashboardSnapshot,
  getOperationalAnalytics,
  listAdminUsers,
  listAuditLogs,
  listBanners,
  listCategories,
  listMessages,
  listMerchantApplications,
  listNotifications,
  listUsers,
  listProducts,
  listRegions,
  listRequests,
  listStores,
  listStoreVerificationRequests,
  getStoreVerificationRequest,
  listTaxonomy,
  moderateStore,
  reviewStoreVerification,
  reconcileStoreVerificationPayment,
  reviewMerchantApplication,
  sendNotification,
  updateAdminMembership,
  updateBanner,
  updateProduct,
  upsertCategory,
  upsertTaxonomy,
} from "./admin-data";
import { signInAdmin } from "./admin-auth";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function numericQuery(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function sendError(response: Response, error: unknown) {
  console.error("[Admin Backend]", error);
  const candidate = error as { code?: unknown; message?: unknown; status?: unknown } | null;
  const code = typeof candidate?.code === "string" ? candidate.code : undefined;
  const rawMessage = typeof candidate?.message === "string" ? candidate.message : error instanceof Error ? error.message : "";
  const status = typeof candidate?.status === "number" && candidate.status >= 400 && candidate.status < 600 ? candidate.status : code === "42501" ? 503 : 500;
  const messageAr = code === "42501"
    ? "رفضت قاعدة بيانات Production العملية بسبب صلاحيات مسار الإدارة. تم تسجيل الخطأ، تحقق من اتصال الخادم المحلي وصلاحياته ثم أعد المحاولة."
    : rawMessage || "تعذر تنفيذ العملية الإدارية الآن.";
  response.status(status).json({
    error: code ?? "admin_backend_error",
    messageAr,
  });
}

async function startServer() {
  const app = express();
  const server = createServer(app);
  app.disable("x-powered-by");
  // Base64 image upload is bounded by the public Storage bucket's 10 MB limit.
  app.use(express.json({ limit: "15mb" }));

  app.get("/api/health", (_request, response) => {
    response.json({ ok: true, service: "assalkom-admin-local", source: "supabase-production" });
  });

  app.post("/api/admin/auth/login", async (request, response) => {
    try {
      const email = typeof request.body?.email === "string" ? request.body.email : "";
      const password = typeof request.body?.password === "string" ? request.body.password : "";
      if (!email || !password) {
        response.status(400).json({ error: "invalid_credentials", messageAr: "أدخل البريد وكلمة المرور." });
        return;
      }
      const session = await signInAdmin(email, password);
      setAdminCookies(response, session);
      response.json({
        user: session.user,
        role: session.role,
        requiresPasswordChange: session.requiresPasswordChange,
        source: "supabase-production",
      });
    } catch (error) {
      response.status(401).json({ error: "admin_login_failed", messageAr: error instanceof Error ? error.message : "تعذر تسجيل الدخول الإداري." });
    }
  });

  app.post("/api/admin/auth/password", async (request, response) => {
    try {
      const session = await getAdminSession(request, response);
      if (!session) { response.status(401).json({ error: "admin_unauthorized", messageAr: "سجّل الدخول إلى الإدارة أولًا." }); return; }
      const newPassword = typeof request.body?.newPassword === "string" ? request.body.newPassword : "";
      const updated = await changeAdminPassword(session, newPassword);
      setAdminCookies(response, updated);
      response.json({ user: updated.user, role: updated.role, source: "supabase-production" });
    } catch (error) { sendError(response, error); }
  });

  app.post("/api/admin/auth/logout", (_request, response) => {
    clearAdminCookies(response);
    response.json({ ok: true });
  });

  app.get("/api/admin/auth/session", async (request, response) => {
    try {
      const session = await getAdminSession(request, response);
      if (!session) {
        response.status(401).json({ error: "admin_unauthorized", messageAr: "سجّل الدخول إلى الإدارة أولًا." });
        return;
      }
      response.json({ user: session.user, role: session.role, requiresPasswordChange: session.requiresPasswordChange, source: "supabase-production" });
    } catch (error) {
      sendError(response, error);
    }
  });

  app.get("/api/admin/admin-users", requireAdmin("admin.manage"), async (_request, response) => {
    try { response.json({ items: await listAdminUsers() }); } catch (error) { sendError(response, error); }
  });
  app.post("/api/admin/admin-users", requireAdmin("admin.manage"), async (request, response) => {
    try { response.status(201).json({ item: await createAdminIdentity(getRequestAdminSession(response), request.body ?? {}) }); } catch (error) { sendError(response, error); }
  });
  app.patch("/api/admin/admin-users/:id", requireAdmin("admin.manage"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await updateAdminMembership(getRequestAdminSession(response), id, request.body ?? {}) });
    } catch (error) { sendError(response, error); }
  });
  app.get("/api/admin/audit-logs", requireAdmin("audit.read"), async (_request, response) => {
    try { response.json({ items: await listAuditLogs() }); } catch (error) { sendError(response, error); }
  });

  app.get("/api/admin/users", requireAdmin("user.read"), async (_request, response) => {
    try { response.json({ items: await listUsers() }); } catch (error) { sendError(response, error); }
  });
  app.delete("/api/admin/users/:id", requireAdmin("user.delete"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await deleteUser(getRequestAdminSession(response), id) });
    } catch (error) { sendError(response, error); }
  });
  app.get("/api/admin/messages", requireAdmin("message.read"), async (_request, response) => {
    try { response.json({ items: await listMessages() }); } catch (error) { sendError(response, error); }
  });
  app.post("/api/admin/storage/public-image", requireAdmin("storage.public.write"), async (request, response) => {
    try {
      response.status(201).json({ item: await uploadPublicImage(getRequestAdminSession(response), request.body ?? {}) });
    } catch (error) { sendError(response, error); }
  });
  app.get("/api/admin/notifications", requireAdmin("notification.write"), async (_request, response) => {
    try { response.json({ items: await listNotifications() }); } catch (error) { sendError(response, error); }
  });
  app.post("/api/admin/notifications", requireAdmin("notification.write"), async (request, response) => {
    try { response.status(201).json({ item: await sendNotification(getRequestAdminSession(response), request.body ?? {}) }); } catch (error) { sendError(response, error); }
  });
  app.get("/api/admin/analytics", requireAdmin("analytics.read"), async (_request, response) => {
    try { response.json(await getOperationalAnalytics()); } catch (error) { sendError(response, error); }
  });

  app.get("/api/admin/overview", requireAdmin("analytics.read"), async (_request, response) => {
    try {
      response.json(await getDashboardSnapshot());
    } catch (error) {
      sendError(response, error);
    }
  });

  const listRoute = (
    pathName: string,
    permission: AdminPermission,
    handler: (options: { page?: number; pageSize?: number; search?: string }) => Promise<unknown>,
  ) => {
    app.get(pathName, requireAdmin(permission), async (request, response) => {
      try {
        response.json(await handler({
          page: numericQuery(request.query.page, 1),
          pageSize: numericQuery(request.query.pageSize, 20),
          search: typeof request.query.search === "string" ? request.query.search : undefined,
        }));
      } catch (error) {
        sendError(response, error);
      }
    });
  };

  listRoute("/api/admin/products", "product.read", listProducts);
  listRoute("/api/admin/stores", "store.read", listStores);
  listRoute("/api/admin/requests", "request.read", listRequests);
  listRoute("/api/admin/merchant-applications", "merchant.review", listMerchantApplications);
  listRoute("/api/admin/store-verification-requests", "verification.read", listStoreVerificationRequests);

  app.get("/api/admin/store-verification-requests/:id", requireAdmin("verification.read_sensitive"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json(await getStoreVerificationRequest(getRequestAdminSession(response), id));
    } catch (error) {
      sendError(response, error);
    }
  });

  app.patch("/api/admin/store-verification-requests/:id", requireAdmin(), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      const action = request.body?.action;
      if (!["approve", "reject", "needs_more_info", "revoke"].includes(action)) {
        response.status(400).json({ error: "invalid_verification_action", messageAr: "إجراء التوثيق غير صالح." });
        return;
      }
      const result = await reviewStoreVerification(
        getRequestAdminSession(response),
        id,
        action as "approve" | "reject" | "needs_more_info" | "revoke",
        typeof request.body?.reviewNote === "string" ? request.body.reviewNote : undefined,
        typeof request.body?.expiresAt === "string" ? request.body.expiresAt : null,
      );
      response.json({ item: result });
    } catch (error) {
      sendError(response, error);
    }
  });

  app.patch("/api/admin/store-verification-requests/:id/payment", requireAdmin("verification.review"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      const paymentStatus = request.body?.paymentStatus;
      if (!["paid", "waived", "failed", "refunded"].includes(paymentStatus)) {
        response.status(400).json({ error: "invalid_payment_status", messageAr: "حالة الدفع غير صالحة." });
        return;
      }
      const result = await reconcileStoreVerificationPayment(
        getRequestAdminSession(response),
        id,
        paymentStatus as "paid" | "waived" | "failed" | "refunded",
        typeof request.body?.paymentReference === "string" ? request.body.paymentReference : undefined,
        typeof request.body?.note === "string" ? request.body.note : undefined,
      );
      response.json({ item: result });
    } catch (error) {
      sendError(response, error);
    }
  });

  app.patch("/api/admin/merchant-applications/:id", requireAdmin("merchant.review"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await reviewMerchantApplication(getRequestAdminSession(response), id, request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });

  app.get("/api/admin/regions", requireAdmin("taxonomy.read"), async (_request, response) => {
    try {
      response.json({ items: await listRegions() });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.get("/api/admin/taxonomy", requireAdmin("taxonomy.read"), async (_request, response) => {
    try {
      response.json({ items: await listTaxonomy() });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.get("/api/admin/categories", requireAdmin("taxonomy.read"), async (_request, response) => {
    try {
      response.json({ items: await listCategories() });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.get("/api/admin/banners", requireAdmin("banner.read"), async (_request, response) => {
    try {
      response.json({ items: await listBanners() });
    } catch (error) {
      sendError(response, error);
    }
  });

  app.post("/api/admin/products", requireAdmin("product.write"), async (request, response) => {
    try {
      const session = getRequestAdminSession(response);
      response.status(201).json({ item: await createProduct(session, request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.delete("/api/admin/products/:id", requireAdmin("product.delete"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await deleteProduct(getRequestAdminSession(response), id) });
    } catch (error) { sendError(response, error); }
  });
  app.patch("/api/admin/products/:id", requireAdmin("product.write"), async (request, response) => {
    try {
      const session = getRequestAdminSession(response);
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await updateProduct(session, id, request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.post("/api/admin/banners", requireAdmin("banner.write"), async (request, response) => {
    try {
      const session = getRequestAdminSession(response);
      response.status(201).json({ item: await createBanner(session, request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.delete("/api/admin/banners/:id", requireAdmin("banner.delete"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await deleteBanner(getRequestAdminSession(response), id) });
    } catch (error) { sendError(response, error); }
  });
  app.patch("/api/admin/banners/:id", requireAdmin("banner.write"), async (request, response) => {
    try {
      const session = getRequestAdminSession(response);
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await updateBanner(session, id, request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.put("/api/admin/categories", requireAdmin("taxonomy.manage"), async (request, response) => {
    try {
      response.json({ item: await upsertCategory(getRequestAdminSession(response), request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.put("/api/admin/taxonomy", requireAdmin("taxonomy.manage"), async (request, response) => {
    try {
      response.json({ item: await upsertTaxonomy(getRequestAdminSession(response), request.body ?? {}) });
    } catch (error) {
      sendError(response, error);
    }
  });
  app.post("/api/admin/requests/:id/reply", requireAdmin("message.write"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await answerRequest(getRequestAdminSession(response), id, request.body?.body) });
    } catch (error) {
      sendError(response, error);
    }
  });

  app.delete("/api/admin/stores/:id", requireAdmin("store.delete"), async (request, response) => {
    try {
      const id = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      response.json({ item: await deleteStore(getRequestAdminSession(response), id) });
    } catch (error) { sendError(response, error); }
  });
  app.post("/api/admin/stores/:id/:action", requireAdmin(), async (request, response) => {
    try {
      const action = Array.isArray(request.params.action) ? request.params.action[0] : request.params.action;
      if (!["approve", "reject", "suspend", "reactivate"].includes(action)) {
        response.status(400).json({ error: "invalid_store_action", messageAr: "إجراء المتجر غير صالح." });
        return;
      }
      const session = getRequestAdminSession(response);
      const storeId = Array.isArray(request.params.id) ? request.params.id[0] : request.params.id;
      const result = await moderateStore(session, storeId, action as "approve" | "reject" | "suspend" | "reactivate");
      response.json({ item: result });
    } catch (error) {
      sendError(response, error);
    }
  });

  const staticPath = process.env.NODE_ENV === "production"
    ? path.resolve(__dirname, "public")
    : path.resolve(__dirname, "..", "dist", "public");
  app.use(express.static(staticPath));
  app.get("/{*splat}", (_request, response) => {
    response.sendFile(path.join(staticPath, "index.html"));
  });

  const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => sendError(response, error);
  app.use(errorHandler);

  const port = numericQuery(process.env.PORT, 3000);
  const host = process.env.ADMIN_BIND_HOST?.trim() || "127.0.0.1";
  server.listen(port, host, () => {
    console.log(`Admin server running on http://${host}:${port}/`);
  });
}

startServer().catch((error) => {
  console.error("[Admin Backend] Startup failed", error);
  process.exitCode = 1;
});
