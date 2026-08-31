import type { MetadataRoute } from 'next'
import {getPublishedListings} from '@/lib/zikos'
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base=process.env.NEXT_PUBLIC_SITE_URL||'https://zikos-three.vercel.app'
  const {data}=await getPublishedListings({})
  const properties=(data||[]).map((x:any)=>({url:`${base}/property/${x.id}`,lastModified:x.updated_at?new Date(x.updated_at):new Date()}))
  return [{url:base,lastModified:new Date()},{url:`${base}/map`,lastModified:new Date()},...properties]
}
