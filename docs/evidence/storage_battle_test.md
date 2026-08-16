# Storage Battle-Test Evidence

## Canonical buckets

The project now has two canonical buckets, created idempotently without deleting the existing `sok1` bucket.

| Bucket | Visibility | Limit | MIME policy | Intended use |
|---|---|---:|---|---|
| `assalkom_public` | Public read | 10 MiB | JPEG, PNG, WebP, SVG | Store/product/banner/gallery media |
| `assalkom_private` | Private | 20 MiB | JPEG, PNG, WebP, PDF | Verification documents and private merchant media |

The bucket settings were created through the Storage API. The migration `database/migrations/0002_storage_canonical_policies.sql` creates canonical policies. Public paths are owned by the first path segment (`auth.uid()`), and Admin may manage them through `public.is_admin()`. Private objects require an authenticated owner or Admin for select/insert/update/delete. The existing `sok1` bucket was left intact for backward compatibility and requires a separate migration when its contents are classified.

## Field test

The test created two isolated confirmed Auth users, uploaded a real 1×1 PNG through the user session, read the public object anonymously, attempted anonymous upload, uploaded a private object, read it as owner, attempted cross-user and anonymous reads, deleted both objects through the Storage DELETE API, and deleted the test Auth users. No test object remained after cleanup.

| Scenario | Expected | Result |
|---|---|---|
| Customer uploads to `assalkom_public/{user_id}/...` | HTTP 200/201 | PASS |
| Anonymous reads public object | HTTP 200 and exact bytes | PASS |
| Anonymous uploads public object | Denied | PASS; API returned authorization-required 400 |
| Customer uploads to `assalkom_private/{user_id}/...` | HTTP 200/201 | PASS |
| Owner reads private object | HTTP 200 and exact bytes | PASS |
| Other customer reads private object | Denied | PASS; object-not-found 404 envelope |
| Anonymous reads private object | Denied | PASS; authorization-required 400 |
| Storage cleanup via DELETE API | HTTP 200 for both objects | PASS |

The authorization-required 400 envelopes are treated as denials, not successes; the API does not expose the object. The cleanup uses the Storage API DELETE endpoint rather than deleting `storage.objects` directly, because direct SQL deletion leaves the underlying object orphaned. See the [Supabase Delete Objects documentation][1].

## Code integration status

The Customer code now has the Storage boundary available through Supabase bootstrap and the Production repository boundary. The next integration task is to replace remaining data-source image URLs with canonical Storage paths and add typed upload/delete methods to the repository so Merchant and Admin use the same policies instead of direct ad hoc calls.

## References

[1]: https://supabase.com/docs/guides/storage/management/delete-objects "Supabase — Delete Objects"
[2]: https://supabase.com/docs/reference/python/storage-from-remove "Supabase — Python Storage Reference"
