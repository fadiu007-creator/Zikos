import { getSupabase } from './supabase'

export type ZikosListing = {
  id: string; title: string; description?: string | null; listing_type: 'sale'|'rent'; property_type: string; price: number; city: string; neighborhood?: string|null; address?: string|null; bedrooms?: number|null; bathrooms?: number|null; area_m2?: number|null; latitude?: number|null; longitude?: number|null; featured?: boolean|null; status?: string|null; owner_id?: string|null; agent_id?: string|null; created_at?: string; updated_at?: string; amenities?: string[]|null; [key:string]: unknown
}

export type ListingFilters = { mode?: 'sale'|'rent'; city?: string; neighborhood?: string; propertyType?: string; minPrice?: number; maxPrice?: number; minBedrooms?: number; minBathrooms?: number; minArea?: number }

export async function getPublishedListings(filters?: ListingFilters) {
  const supabase = getSupabase()
  if (!supabase) return { data: [], error: new Error('Supabase environment variables are missing') }
  let query = supabase.from('zikos_listings').select('*').eq('status','published').order('featured',{ascending:false}).order('created_at',{ascending:false})
  if (filters?.mode) query=query.eq('listing_type',filters.mode)
  if (filters?.city) query=query.or(`city.ilike.%${filters.city}%,neighborhood.ilike.%${filters.city}%`)
  if (filters?.neighborhood) query=query.ilike('neighborhood',`%${filters.neighborhood}%`)
  if (filters?.propertyType && filters.propertyType!=='All types') query=query.eq('property_type',filters.propertyType.toLowerCase())
  if (filters?.minPrice!=null) query=query.gte('price',filters.minPrice)
  if (filters?.maxPrice!=null) query=query.lte('price',filters.maxPrice)
  if (filters?.minBedrooms!=null) query=query.gte('bedrooms',filters.minBedrooms)
  if (filters?.minBathrooms!=null) query=query.gte('bathrooms',filters.minBathrooms)
  if (filters?.minArea!=null) query=query.gte('area_m2',filters.minArea)
  return query
}

export async function getCurrentUser(){const supabase=getSupabase();if(!supabase)return null;const {data}=await supabase.auth.getUser();return data.user}
