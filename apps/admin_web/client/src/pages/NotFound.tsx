import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { HelpCircle, Home } from "lucide-react";
import { useLocation } from "wouter";

export default function NotFound() {
  const [, setLocation] = useLocation();

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-[#0d0906] px-5" dir="rtl">
      <Card className="w-full max-w-lg border-[#38291d] bg-[#1a120c] shadow-[0_24px_70px_rgba(0,0,0,.45)]">
        <CardContent className="pt-8 pb-8 text-center">
          <div className="flex justify-center mb-6">
            <div className="grid size-16 place-items-center rounded-2xl bg-[#332416] text-[#f5a623]">
              <HelpCircle className="size-8" />
            </div>
          </div>
          <h1 className="text-4xl font-bold text-[#f7ede2] mb-2" dir="ltr">404</h1>
          <h2 className="text-xl font-semibold text-[#f7ede2] mb-4">الصفحة غير موجودة</h2>
          <p className="text-[#c9b6a3] mb-8 leading-relaxed">
            عذرًا، الصفحة التي تبحث عنها غير متاحة أو لم تُبنَ بعد في تجربة عسلكم.
          </p>
          <Button onClick={() => setLocation("/")} className="bg-[#f5a623] text-[#2b1a12] hover:bg-[#ffc45e]">
            <Home className="ml-2 size-4" />العودة إلى لوحة الإدارة
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
