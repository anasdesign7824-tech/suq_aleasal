import { describe, expect, it } from "vitest";
import type { AdminSession } from "./admin-auth";
import {
  activateSubscriptionForUser,
  deleteBanner,
  deleteProduct,
  deleteStore,
  deleteUser,
  moderateStore,
  reconcilePaymentRequest,
  reconcileStoreVerificationPayment,
  reviewStoreVerification,
  setMerchantSubscriptionStatus,
  updateAdminMembership,
  updateDesignRequest,
  updateProduct,
} from "./admin-data";

const moderatorSession: AdminSession = {
  accessToken: "test-access-token",
  user: { id: "moderator-id", email: "moderator@example.com", user_metadata: {} },
  role: {
    id: "moderator-role",
    code: "moderator",
    nameAr: "مراجع",
    permissions: {
      "review.read": true,
      "product.read": true,
      "request.read": true,
      "merchant.review": true,
      "review.moderate": true,
    },
  },
  requiresPasswordChange: false,
};

const targetId = "00000000-0000-0000-0000-000000000001";

async function expectPermissionRejection(operation: Promise<unknown>, message: string) {
  await expect(operation).rejects.toThrow(message);
}

describe("Admin IDOR permission boundaries", () => {
  it("rejects delete mutations for a moderator regardless of the target ID", async () => {
    await expectPermissionRejection(deleteStore(moderatorSession, targetId), "لا تملك صلاحية حذف المتجر");
    await expectPermissionRejection(deleteProduct(moderatorSession, targetId), "لا تملك صلاحية حذف المنتج");
    await expectPermissionRejection(deleteBanner(moderatorSession, targetId), "لا تملك صلاحية حذف البانر");
    await expectPermissionRejection(deleteUser(moderatorSession, targetId), "لا تملك صلاحية حذف المستخدم");
  });

  it("rejects write and review mutations for a moderator regardless of the target ID", async () => {
    await expectPermissionRejection(updateProduct(moderatorSession, targetId, { nameAr: "تغيير غير مصرح" }), "لا تملك صلاحية تعديل المنتج");
    await expectPermissionRejection(updateDesignRequest(moderatorSession, targetId, { status: "completed" }), "لا تملك صلاحية إدارة طلبات التصميم");
    await expectPermissionRejection(moderateStore(moderatorSession, targetId, "approve"), "لا تملك صلاحية تعديل المتجر");
    await expectPermissionRejection(reviewStoreVerification(moderatorSession, targetId, "approve"), "لا تملك صلاحية مراجعة توثيق المتجر");
    await expectPermissionRejection(reconcileStoreVerificationPayment(moderatorSession, targetId, "paid"), "لا تملك صلاحية تسوية رسوم توثيق المتجر");
    await expectPermissionRejection(reconcilePaymentRequest(moderatorSession, targetId, "confirmed"), "لا تملك صلاحية تسوية طلب الدفع");
    await expectPermissionRejection(setMerchantSubscriptionStatus(moderatorSession, targetId, "active"), "لا تملك صلاحية تفعيل الخطط");
    await expectPermissionRejection(activateSubscriptionForUser(moderatorSession, targetId, targetId), "لا تملك صلاحية تفعيل الخطط");
    await expectPermissionRejection(updateAdminMembership(moderatorSession, targetId, { isActive: false }), "لا تملك صلاحية إدارة المديرين");
  });

  it("does not treat merchant review permission as a global write permission", () => {
    expect(moderatorSession.role.permissions["merchant.review"]).toBe(true);
    expect(moderatorSession.role.permissions["store.approve"]).toBeUndefined();
    expect(moderatorSession.role.permissions["product.write"]).toBeUndefined();
    expect(moderatorSession.role.permissions["user.delete"]).toBeUndefined();
  });
});
