import './globals.css'
import type { Metadata } from 'next'
export const metadata: Metadata={title:'Zikos — Real Estate in Kosovo',description:'Find homes, apartments, land and commercial property in Kosovo.'}
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}