import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source_path = root / "references" / "data" / "yemeni_honey_master_database_final.json"
output_path = root / "packages" / "demo_data" / "data" / "demo_catalog.json"
source = json.loads(source_path.read_text(encoding="utf-8"))

regions = [
    {"id": "region-hadramout", "name_ar": "حضرموت", "name_en": "Hadramout", "code": "HD"},
    {"id": "region-amran", "name_ar": "عمران", "name_en": "Amran", "code": "AM"},
    {"id": "region-shabwah", "name_ar": "شبوة", "name_en": "Shabwah", "code": "SH"},
    {"id": "region-sanaa", "name_ar": "صنعاء", "name_en": "Sana'a", "code": "SN"},
]

stores = [
    {
        "id": "demo-store-doani",
        "merchant_id": "demo-merchant-doani",
        "name_ar": "مناحل دوعن الأصيلة",
        "slug": "manahil-doan-alaseela",
        "description": "عسل سدر يمني أصيل من وادي دوعن، مع توثيق المصدر ومعلومات القطفة.",
        "region_id": "region-hadramout",
        "logo_url": "assets/brand/logo-internal.svg",
        "cover_url": "assets/brand/logo-internal.svg",
        "is_verified": True,
        "status": "active",
        "rating_average": 4.9,
        "review_count": 18,
        "followers_count": 126,
    },
    {
        "id": "demo-store-amran",
        "merchant_id": "demo-merchant-amran",
        "name_ar": "سوق العسل العصيمي",
        "slug": "souq-alasal-osaimi",
        "description": "منتجات نحلية يمنية مختارة من العصيمات وقَفلة عذر، للذوق اليومي والهدايا.",
        "region_id": "region-amran",
        "logo_url": "assets/brand/logo-internal.svg",
        "cover_url": "assets/brand/logo-internal.svg",
        "is_verified": True,
        "status": "active",
        "rating_average": 4.7,
        "review_count": 11,
        "followers_count": 87,
    },
    {
        "id": "demo-store-sanaa",
        "merchant_id": "demo-merchant-sanaa",
        "name_ar": "بيت العسل والخلطات",
        "slug": "bait-alasal-mixes",
        "description": "خلطات نحلية وهدايا تراثية تُجهز محليًا مع خيارات استلام وتواصل مباشرة.",
        "region_id": "region-sanaa",
        "logo_url": "assets/brand/logo-internal.svg",
        "cover_url": "assets/brand/logo-internal.svg",
        "is_verified": False,
        "status": "active",
        "rating_average": 4.5,
        "review_count": 7,
        "followers_count": 54,
    },
]

products = []
store_index = 0
for category in source["categories"]:
    category_products = list(category.get("products", []))
    for subcategory in category.get("sub_categories", []):
        category_products.extend({**product, "subcategory_id": subcategory["id"], "subcategory_name_ar": subcategory["name_ar"]} for product in subcategory.get("products", []))
    for product in category_products:
        product_id = product["id"]
        products.append({
            "id": f"demo-{product_id.lower()}",
            "source_id": product_id,
            "store_id": stores[store_index % len(stores)]["id"],
            "category_id": category["id"],
            "category_name_ar": category["name_ar"],
            "subcategory_id": product.get("subcategory_id"),
            "subcategory_name_ar": product.get("subcategory_name_ar"),
            "name_ar": product["name_ar"],
            "name_en": None,
            "description": product.get("description"),
            "product_type": "honey" if category["id"] == "CAT-001" else "wax" if category["id"] == "CAT-002" else "mix" if category["id"] == "CAT-003" else "raw" if category["id"] == "CAT-004" else "gift",
            "status": "active",
            "grade_levels": product.get("grades", []),
            "badges": product.get("badges", []),
            "tags": product.get("tags", []),
            "regions": product.get("regions", []),
            "components": product.get("components", []),
            "purpose": product.get("purpose"),
            "forms": product.get("forms", []),
            "is_featured": bool(product.get("badges")),
            "primary_image_url": "assets/brand/logo-internal.svg",
            "rating_average": round(4.3 + ((store_index % 4) * 0.15), 1),
            "review_count": 3 + (store_index % 6),
        })
        store_index += 1

reviews = [
    {"id": "demo-review-001", "product_id": "demo-prod-sidr-doani", "store_id": "demo-store-doani", "author_id": "demo-user-001", "rating": 5, "status": "approved", "body": "طعم أصيل وتغليف مرتب."},
    {"id": "demo-review-002", "product_id": "demo-prod-sidr-osaimi", "store_id": "demo-store-amran", "author_id": "demo-user-002", "rating": 4, "status": "approved", "body": "مذاق قوي ومعلومات المنتج واضحة."},
    {"id": "demo-review-003", "product_id": "demo-mix-immunity", "store_id": "demo-store-sanaa", "author_id": "demo-user-003", "rating": 5, "status": "approved", "body": "خلطة مناسبة كهدية وتجربة مختلفة."},
]

catalog = {
    "demo_only": True,
    "source": source["database_info"],
    "global_settings": source["global_settings"],
    "regions": regions,
    "stores": stores,
    "products": products,
    "reviews": reviews,
    "requests": [
        {"id": "demo-request-001", "requester_id": "demo-user-001", "store_id": "demo-store-doani", "subject": "أرغب في معرفة خيارات نصف الكيلو", "body": "هل تتوفر عبوة نصف كيلو من سدر دوعني؟", "status": "open", "preferred_handoff_option": "pickup"},
        {"id": "demo-request-002", "requester_id": "demo-user-002", "store_id": "demo-store-sanaa", "subject": "طلب باقة هدية", "body": "أحتاج صندوقًا تراثيًا مع بطاقة تهنئة.", "status": "answered", "preferred_handoff_option": "merchant_delivery"},
    ],
    "notifications": [
        {"id": "demo-notification-001", "user_id": "demo-user-001", "notification_type": "welcome", "title_ar": "مرحبًا بك في عسلكم", "body_ar": "اكتشف العسل اليمني من مصادره.", "payload": {}, "read_at": None},
        {"id": "demo-notification-002", "user_id": "demo-merchant-doani", "notification_type": "request", "title_ar": "لديك طلب تواصل جديد", "body_ar": "راجع طلب العميل وأرسل ردك.", "payload": {"request_id": "demo-request-001"}, "read_at": None},
    ],
}

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"products={len(products)} stores={len(stores)} reviews={len(reviews)} output={output_path}")
