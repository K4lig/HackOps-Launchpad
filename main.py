from fastapi import FastAPI, HTTPException
import httpx

app = FastAPI(title="CVE Copilot API")
NVD = "https://services.nvd.nist.gov/rest/json/cves/2.0"

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/cve/{cve_id}")
async def get_cve(cve_id: str):
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(NVD, params={"cveId": cve_id.upper()})
    data = r.json().get("vulnerabilities", [])
    if not data:
        raise HTTPException(404, "CVE no encontrado")
    cve = data[0]["cve"]
    return {"id": cve["id"], "description": cve["descriptions"][0]["value"]}