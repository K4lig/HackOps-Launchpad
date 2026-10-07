import logging
import os
import re

import httpx
from fastapi import FastAPI, HTTPException
from openai import AsyncOpenAI

logger = logging.getLogger("cve-api")

app = FastAPI(title="CVE Copilot API")

NVD = "https://services.nvd.nist.gov/rest/json/cves/2.0"
CVE_PATTERN = re.compile(r"CVE-\d{4}-\d{4,}")

llm = AsyncOpenAI(
    base_url=os.getenv("LLM_BASE_URL"),
    api_key=os.getenv("LLM_API_KEY", "missing"),
)
MODEL = os.getenv("LLM_MODEL", "gpt-5-mini")


def validate_cve_id(cve_id: str) -> str:
    cve_id = cve_id.strip().upper()
    if not CVE_PATTERN.fullmatch(cve_id):
        raise HTTPException(400, {"error": "Invalid CVE format", "expected": "CVE-YYYY-NNNN"})
    return cve_id


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/cve/{cve_id}")
async def get_cve(cve_id: str):
    cve_id = validate_cve_id(cve_id)
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.get(NVD, params={"cveId": cve_id})
    data = r.json().get("vulnerabilities", [])
    if not data:
        raise HTTPException(404, f"CVE '{cve_id}' no encontrado")
    cve = data[0]["cve"]
    return {"id": cve["id"], "description": cve["descriptions"][0]["value"]}


@app.get("/api/explain/{cve_id}")
async def explain(cve_id: str):
    cve = await get_cve(cve_id)  # valida y lanza 400/404 si corresponde
    try:
        resp = await llm.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": (
                    "Eres un analista de ciberseguridad senior. "
                    "Explica la vulnerabilidad en español en máximo 5 líneas. "
                    "Incluye qué es, impacto potencial y mitigación recomendada.")},
                {"role": "user", "content": f"ID: {cve['id']}\nDescripción: {cve['description']}"},
            ],
            max_completion_tokens=2000,
        )
    except Exception:
        logger.exception("Fallo al llamar al modelo para %s", cve["id"])
        raise HTTPException(502, "No se pudo generar la explicación. Intenta más tarde.")
    return {"id": cve["id"], "explanation": resp.choices[0].message.content}
