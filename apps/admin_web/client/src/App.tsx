import { Route, Switch } from "wouter";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import ErrorBoundary from "@/components/ErrorBoundary";
import AdminAuthGate from "@/components/AdminAuthGate";
import Home from "@/pages/Home";
import Landing from "@/pages/Landing";
import NotFound from "@/pages/NotFound";

export default function App() {
  return <ErrorBoundary><AdminAuthGate>{({ session, logout }) => <TooltipProvider><Toaster richColors position="bottom-left" /><Switch><Route path="/" component={() => <Home session={session} onLogout={logout} />} /><Route path="/landing" component={Landing} /><Route component={NotFound} /></Switch></TooltipProvider>}</AdminAuthGate></ErrorBoundary>;
}
