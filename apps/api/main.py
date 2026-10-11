import logging
import os
import re

import httpx
from fastapi import FastAPI, HTTPException
from openai import AsyncOpenAI
from pathlib import Path

logger = logging.getLogger("cve-api")

app = FastAPI(title="CVE Copilot API")

NVD = "https://services.nvd.nist.gov/rest/json/cves/2.0"
CVE_PATTERN = re.compile(r"CVE-\d{4}-\d{4,}")

def get_secret(name: str, env_var: str) -> str:
    path = Path("/mnt/secrets") / name
    if path.exists():
        return path.read_text().strip()
    return os.getenv(env_var, "missing")

llm = AsyncOpenAI(
    base_url=os.getenv("LLM_BASE_URL"),
    api_key=get_secret("llm-api-key", "LLM_API_KEY"),
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
    headers = {}
    nvd_key = get_secret("nvd-api-key", "NVD_API_KEY")
    if nvd_key != "missing":
        headers["apiKey"] = nvd_key
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get(NVD, params={"cveId": cve_id}, headers=headers)
        r.raise_for_status()
        data = r.json().get("vulnerabilities", [])
    except httpx.HTTPStatusError as e:
        logger.warning("NVD respondio %s para %s", e.response.status_code, cve_id)
        raise HTTPException(502, "No se pudo consultar la base de datos de CVEs. Intenta mas tarde.")
    except (httpx.HTTPError, ValueError):
        logger.exception("Fallo al consultar NVD para %s", cve_id)
        raise HTTPException(502, "No se pudo consultar la base de datos de CVEs. Intenta mas tarde.")
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
