import type { Metadata } from "next";
import "./globals.css";
import { SiteHeader } from "@/components/site-header";
export const metadata: Metadata = { title: "JelajahHub — Temukan Perjalananmu", description: "Marketplace paket Umroh, Haji, wisata domestik, dan internasional dari perusahaan travel." };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="id"><body><SiteHeader/><main>{children}</main><footer className="footer"><div className="container footer-inner"><span>© {new Date().getFullYear()} JelajahHub</span><span>Temukan perjalanan dari agen travel terkurasi.</span></div></footer></body></html>; }
