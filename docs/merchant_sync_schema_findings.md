# Production merchant synchronization schema findings

| Table | Columns |
|---|---|
| `audit_logs` | `id` (uuid, required)<br>`actor_user_id` (uuid, nullable)<br>`action` (text, required)<br>`entity_type` (text, required)<br>`entity_id` (uuid, nullable)<br>`metadata` (jsonb, required)<br>`created_at` (timestamp with time zone, required) |
| `merchant_application_drafts` | `user_id` (uuid, required)<br>`display_name` (text, required)<br>`phone` (text, required)<br>`experience` (text, required)<br>`location` (text, required)<br>`specialties` (text, required)<br>`certificate_note` (text, nullable)<br>`updated_at` (timestamp with time zone, required) |
| `merchant_applications` | `id` (uuid, required)<br>`user_id` (uuid, required)<br>`display_name` (text, required)<br>`phone` (text, required)<br>`experience` (text, required)<br>`location` (text, required)<br>`specialties` (text, required)<br>`certificate_note` (text, nullable)<br>`status` (text, required)<br>`submitted_at` (timestamp with time zone, required)<br>`reviewed_at` (timestamp with time zone, nullable)<br>`reviewed_by` (uuid, nullable)<br>`review_note` (text, nullable) |
| `merchant_profiles` | `user_id` (uuid, required)<br>`business_name` (text, required)<br>`legal_name` (text, nullable)<br>`description` (text, nullable)<br>`verification_status` (text, required)<br>`verified_at` (timestamp with time zone, nullable)<br>`created_at` (timestamp with time zone, required)<br>`updated_at` (timestamp with time zone, required) |
| `notifications` | `id` (uuid, required)<br>`user_id` (uuid, required)<br>`notification_type` (text, required)<br>`title_ar` (text, required)<br>`body_ar` (text, nullable)<br>`payload` (jsonb, required)<br>`read_at` (timestamp with time zone, nullable)<br>`created_at` (timestamp with time zone, required) |
| `products` | `id` (uuid, required)<br>`store_id` (uuid, required)<br>`taxonomy_id` (uuid, nullable)<br>`name_ar` (text, required)<br>`name_en` (text, nullable)<br>`description` (text, nullable)<br>`product_type` (text, required)<br>`grade_level` (smallint, nullable)<br>`status` (text, required)<br>`is_featured` (boolean, required)<br>`metadata` (jsonb, required)<br>`created_at` (timestamp with time zone, required)<br>`updated_at` (timestamp with time zone, required) |
| `profiles` | `user_id` (uuid, required)<br>`display_name` (text, required)<br>`phone` (text, nullable)<br>`avatar_url` (text, nullable)<br>`bio` (text, nullable)<br>`role` (text, required)<br>`locale` (text, required)<br>`is_active` (boolean, required)<br>`created_at` (timestamp with time zone, required)<br>`updated_at` (timestamp with time zone, required) |
| `stores` | `id` (uuid, required)<br>`merchant_id` (uuid, required)<br>`region_id` (uuid, nullable)<br>`name_ar` (text, required)<br>`slug` (text, required)<br>`description` (text, nullable)<br>`phone` (text, nullable)<br>`logo_url` (text, nullable)<br>`cover_url` (text, nullable)<br>`status` (text, required)<br>`is_verified` (boolean, required)<br>`created_at` (timestamp with time zone, required)<br>`updated_at` (timestamp with time zone, required) |
| `users` | `id` (uuid, required)<br>`created_at` (timestamp with time zone, required)<br>`last_seen_at` (timestamp with time zone, nullable) |

## Key findings

- `profiles.role` is customer/merchant/admin and `merchant_profiles.verification_status` is pending/verified/rejected/suspended.
- `stores.status` is pending/active/paused/rejected/suspended and `is_verified` is separate.
- `merchant_applications.status` currently needs alignment with the UI review vocabulary and activation workflow.
- `users` currently stores `created_at` and `last_seen_at`; IP/device/session telemetry is not present in this table and must not be fabricated.
