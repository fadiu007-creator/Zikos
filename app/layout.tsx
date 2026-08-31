import './globals.css'
import type { Metadata, Viewport } from 'next'
export const metadata: Metadata={metadataBase:new URL(process.env.NEXT_PUBLIC_SITE_URL||'https://zikos-three.vercel.app'),title:{default:'Zikos — Real Estate in Kosovo',template:'%s | Zikos'},description:'Find homes, apartments, land and commercial property in Kosovo.',applicationName:'Zikos',keywords:['real estate Kosovo','apartments Kosovo','houses Kosovo','property Prishtina','property Ferizaj','property Prizren'],openGraph:{title:'Zikos — Real Estate in Kosovo',description:'Find homes, apartments, land and commercial property in Kosovo.',type:'website',locale:'en_XK',siteName:'Zikos'}}
export const viewport: Viewport={width:'device-width',initialScale:1,themeColor:'#123d34'}
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
