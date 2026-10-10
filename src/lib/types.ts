export type TravelCategory = "umroh" | "haji" | "domestik" | "internasional";
export type ApprovalStatus = "pending" | "approved" | "rejected" | "suspended";
export type TravelPackage = { id:string; title:string; slug:string; category:TravelCategory; destination:string; price:number; duration_days:number; summary:string|null; cover_image:string|null; company_id:string; travel_companies?:{name:string;slug:string;whatsapp:string|null}; };
