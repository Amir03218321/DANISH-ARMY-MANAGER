// DANIX access-request Worker. Keep GITHUB_TOKEN only in Cloudflare Secrets.
export default {
  async fetch(request, env) {
    const headers = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Methods":"POST, OPTIONS","Access-Control-Allow-Headers":"Content-Type","Content-Type":"application/json"};
    if (request.method === "OPTIONS") return new Response(null,{status:204,headers});
    if (request.method !== "POST") return new Response(JSON.stringify({ok:false,error:"POST required"}),{status:405,headers});
    try {
      const body = await request.json();
      const userId = String(body.userId || "").trim();
      const appVersion = String(body.appVersion || "unknown").trim().slice(0,40);
      if (!/^[A-Fa-f0-9]{8,32}$/.test(userId)) return new Response(JSON.stringify({ok:false,error:"Invalid userId"}),{status:400,headers});
      if (!env.GITHUB_TOKEN) return new Response(JSON.stringify({ok:false,error:"Worker secret is not configured"}),{status:500,headers});
      const gh = await fetch("https://api.github.com/repos/Amir03218321/DANIX-IMPROVEMENTS/issues",{
        method:"POST",
        headers:{Authorization:`Bearer ${env.GITHUB_TOKEN}`,Accept:"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28","User-Agent":"DANIX-Access-Request-Worker","Content-Type":"application/json"},
        body:JSON.stringify({title:`DANIX access request — ${userId}`,body:`A user requested access to DANISH ARMY TMP MANAGER.\\n\\nUser ID: ${userId}\\nApp version: ${appVersion}\\n\\nApprove by adding USER_ID|EXPIRY_UNIX to approved-users.txt in FREE-FIRE-PANEL. Use 0 for no expiry.`})
      });
      const result = await gh.json().catch(()=>({}));
      if (!gh.ok) return new Response(JSON.stringify({ok:false,error:result.message || `GitHub API error ${gh.status}`}),{status:502,headers});
      return new Response(JSON.stringify({ok:true,issueNumber:result.number,issueUrl:result.html_url}),{status:201,headers});
    } catch {
      return new Response(JSON.stringify({ok:false,error:"Invalid request"}),{status:400,headers});
    }
  }
};
