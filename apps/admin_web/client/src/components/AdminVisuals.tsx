import { ImageOff, ShieldCheck } from "lucide-react";
import { useState } from "react";

export function AdminSafeImage({
  src,
  alt,
  className = "size-full object-cover",
  fallbackClassName = "grid size-full place-items-center bg-[#fff0d6] text-[#9c5a00]",
}: {
  src?: string | null;
  alt: string;
  className?: string;
  fallbackClassName?: string;
}) {
  const [failed, setFailed] = useState(false);
  const normalized = src?.trim();
  if (!normalized || failed) {
    return (
      <div className={fallbackClassName} role="img" aria-label={`لا تتوفر صورة ${alt}`}>
        <ImageOff className="size-5" aria-hidden="true" />
      </div>
    );
  }
  return <img src={normalized} alt={alt} className={className} onError={() => setFailed(true)} />;
}

export function AdminPremiumBadge({ label = "ميزة مدفوعة" }: { label?: string }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full bg-gradient-to-l from-[#9c5a00] to-[#4f2e1f] px-2.5 py-1 text-[11px] font-bold text-[#fffaf3]">
      <ShieldCheck className="size-3.5" aria-hidden="true" />
      {label}
    </span>
  );
}
