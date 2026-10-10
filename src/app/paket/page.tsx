
"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import PackageGrid from "@/components/package-grid";

function PackagesContent() {
  const params = useSearchParams();
  const initial = params.get("category") || "";
  const [category, setCategory] = useState(initial);
  const [search, setSearch] = useState("");
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function run() {
      setLoading(true);

      try {
        const supabase = createClient();

        let query = supabase
          .from("travel_packages")
          .select(
            "id,title,slug,category,destination,price,duration_days,summary,cover_image,company_id,travel_companies!inner(name,slug,whatsapp,status)"
          )
          .eq("status", "approved")
          .eq("travel_companies.status", "approved")
          .order("created_at", { ascending: false });

        if (category) {
          query = query.eq("category", category);
        }

        if (search.trim()) {
          query = query.or(
            `title.ilike.%${search.trim()}%,destination.ilike.%${search.trim()}%`
          );
        }

        const { data, error } = await query;

        if (error) throw error;

        setItems(data ?? []);
      } catch (error) {
        console.error("Gagal memuat paket:", error);
        setItems([]);
      } finally {
        setLoading(false);
      }
    }

    run();
  }, [category, search]);

  return (
    <div className="page container">
      <div className="section-head">
        <div>
          <span className="eyebrow">Katalog perjalanan</span>
          <h2>Temukan paket perjalanan</h2>
          <p className="muted">
            Pilih paket dan hubungi perusahaan travel secara langsung.
          </p>
        </div>
      </div>

      <div className="search-row">
        <input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder="Cari paket atau destinasi..."
        />

        <select
          value={category}
          onChange={(event) => setCategory(event.target.value)}
        >
          <option value="">Semua kategori</option>
          <option value="umroh">Umroh</option>
          <option value="haji">Haji</option>
          <option value="domestik">Wisata domestik</option>
          <option value="internasional">Wisata internasional</option>
        </select>
      </div>

      {loading ? (
        <div className="empty">Memuat paket...</div>
      ) : (
        <PackageGrid packages={items} />
      )}
    </div>
  );
}

export default function Packages() {
  return (
    <Suspense
      fallback={
        <div className="page container">
          <div className="empty">Memuat paket...</div>
        </div>
      }
    >
      <PackagesContent />
    </Suspense>
  );
}
