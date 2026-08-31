'use client'
export default function Error({reset}:{error:Error&{digest?:string};reset:()=>void}){return <main style={{minHeight:'100vh',display:'grid',placeItems:'center',padding:24,textAlign:'center'}}><div><h1>Something went wrong</h1><p>Please try again.</p><button onClick={()=>reset()} style={{padding:'10px 16px',borderRadius:10,border:0,cursor:'pointer'}}>Try again</button></div></main>}
