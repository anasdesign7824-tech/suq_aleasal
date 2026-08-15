// Design: دار العسل التحريرية — route shell kept intentionally quiet around the operational dashboard.
import { Route, Switch } from "wouter";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import ErrorBoundary from "@/components/ErrorBoundary";
import Home from "@/pages/Home";
import NotFound from "@/pages/NotFound";

export default function App() {
  return <ErrorBoundary><TooltipProvider><Toaster richColors position="bottom-left" /><Switch><Route path="/" component={Home} /><Route component={NotFound} /></Switch></TooltipProvider></ErrorBoundary>;
}
