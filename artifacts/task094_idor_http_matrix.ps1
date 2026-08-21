$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:3213'
$origin = $base
$id = '00000000-0000-0000-0000-000000000001'
$cases = @(
  @{ name = 'delete_store'; method = 'DELETE'; path = "/api/admin/stores/$id" },
  @{ name = 'moderate_store'; method = 'POST'; path = "/api/admin/stores/$id/approve" },
  @{ name = 'delete_product'; method = 'DELETE'; path = "/api/admin/products/$id" },
  @{ name = 'update_product'; method = 'PATCH'; path = "/api/admin/products/$id" },
  @{ name = 'delete_banner'; method = 'DELETE'; path = "/api/admin/banners/$id" },
  @{ name = 'update_banner'; method = 'PATCH'; path = "/api/admin/banners/$id" },
  @{ name = 'review_store_verification'; method = 'PATCH'; path = "/api/admin/store-verification-requests/$id" },
  @{ name = 'reconcile_store_verification_payment'; method = 'PATCH'; path = "/api/admin/store-verification-requests/$id/payment" },
  @{ name = 'review_merchant_application'; method = 'PATCH'; path = "/api/admin/merchant-applications/$id" },
  @{ name = 'reconcile_payment_request'; method = 'PATCH'; path = "/api/admin/payment-requests/$id" },
  @{ name = 'set_subscription_status'; method = 'PATCH'; path = "/api/admin/subscriptions/$id" },
  @{ name = 'activate_subscription_for_user'; method = 'POST'; path = '/api/admin/subscriptions/activate' },
  @{ name = 'update_design_request'; method = 'PATCH'; path = "/api/admin/design-requests/$id" },
  @{ name = 'answer_request'; method = 'POST'; path = "/api/admin/requests/$id/reply" },
  @{ name = 'delete_delivery_option'; method = 'DELETE'; path = "/api/admin/logistics/delivery-options/$id" },
  @{ name = 'delete_pickup_location'; method = 'DELETE'; path = "/api/admin/logistics/pickup-locations/$id" },
  @{ name = 'update_admin_membership'; method = 'PATCH'; path = "/api/admin/admin-users/$id" },
  @{ name = 'delete_user'; method = 'DELETE'; path = "/api/admin/users/$id" }
)
$results = foreach ($case in $cases) {
  $status = (& curl.exe -sS -o NUL -w '%{http_code}' -X $case.method -H "Origin: $origin" "$base$($case.path)").Trim()
  [pscustomobject]@{ name = $case.name; method = $case.method; path = $case.path; status = [int]$status }
}
$results | ConvertTo-Json -Depth 3
$results | ConvertTo-Json -Depth 3 | Set-Content -Path '.\artifacts\task094_idor_http_matrix.json' -Encoding utf8
