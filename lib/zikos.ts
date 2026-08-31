import { getSupabase } from './supabase'

export async function getPublishedListings(filters?: { mode?: 'sale'|'rent'; city?: string; propertyType?: string; maxPrice?: number }) {
  const supabase = getSupabase()
  if (!supabase) return { data: [], error: new Error('Supabase environment variables are missing') }
  let query = supabase.from('zikos_listings').select('*').eq('status', 'published').order('featured', { ascending: false }).order('created_at', { ascending: false })
  if (filters?.mode) query = query.eq('listing_type', filters.mode)
  if (filters?.city) query = query.ilike('city', `%${filters.city}%`)
  if (filters?.propertyType && filters.propertyType !== 'All types') query = query.eq('property_type', filters.propertyType.toLowerCase())
  if (filters?.maxPrice) query = query.lte('price', filters.maxPrice)
  return query
}

export async function getCurrentUser() {
  const supabase = getSupabase()
  if (!supabase) return null
  const { data } = await supabase.auth.getUser()
  return data.user
}
