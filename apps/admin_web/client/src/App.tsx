// Design: دار العسل التحريرية — route shell kept intentionally quiet around the operational dashboard.
import { Route, Switch } from "wouter";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import ErrorBoundary from "@/components/ErrorBoundary";
import Home from "@/pages/Home";
import Landing from "@/pages/Landing";
import NotFound from "@/pages/NotFound";

export default function App() {
  return <ErrorBoundary><TooltipProvider><Toaster richColors position="bottom-left" /><Switch><Route path="/" component={Home} /><Route path="/landing" component={Landing} /><Route component={NotFound} /></Switch></TooltipProvider></ErrorBoundary>;
}
