"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
export function SiteHeader(){ const [email,setEmail]=useState<string|null>(null); useEffect(()=>{ const supabase=createClient(); supabase.auth.getUser().then(({data})=>setEmail(data.user?.email??null)); const {data:{subscription}}=supabase.auth.onAuthStateChange((_e,session)=>setEmail(session?.user?.email??null)); return ()=>subscription.unsubscribe(); },[]); return <header className="header"><div className="container nav"><Link className="brand" href="/"><span className="brand-mark">J</span> Jelajah<span className="brand-light">Hub</span></Link><nav><Link href="/#paket">Jelajahi paket</Link><Link href="/daftar">Gabung sebagai travel</Link>{email?<Link className="nav-cta" href="/dashboard">Dashboard</Link>:<Link className="nav-cta" href="/login">Masuk</Link>}</nav></div></header> }
