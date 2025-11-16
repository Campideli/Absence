import re
import io
import os
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import pdfplumber

def parse_subjects_list(first_page_text):
    """Extrai a lista de matérias apenas do texto da primeira página."""
    subjects = {}
    if not first_page_text:
        return subjects
    
    lines = first_page_text.split("\n")
    found_start = False
    
    for line in lines:
        if "RELAÇÃO DE DISCIPLINAS" in line or "RELACAO DE DISCIPLINAS" in line:
            found_start = True
            continue
        
        if not found_start or not line.strip() or not line.strip()[0].isdigit():
            continue
        
        if line.strip().startswith("OBS"):
            break
        
        parts = re.split(r'\s+', line.strip())
        
        if len(parts) >= 6:
            code = parts[0]
            name = " ".join(parts[2:-5]).title()
            tp = parts[-4]
            
            # Clean PDF special characters like (cid:10), (cid:13), etc.
            max_absences_str = re.sub(r'\(cid:\d+\)', '', parts[-1]).strip()
            
            try:
                max_absences = int(max_absences_str)
            except ValueError:
                max_absences = 0
            
            if name and tp:
                subjects[code] = {
                    "name": name,
                    "tp": tp,
                    "maxAbsences": max_absences
                }
    
    return subjects

# ==================== CORS CONFIGURATION ====================
def get_allowed_origins():
    """
    Obtém as origens permitidas do ambiente com validação de segurança.
    Em produção, rejeita wildcard e localhost.
    """
    environment = os.getenv('ENVIRONMENT', 'development')
    allowed_origins_env = os.getenv('ALLOWED_ORIGINS', '')
    
    # Parse da lista de origens
    if allowed_origins_env:
        origins = [origin.strip() for origin in allowed_origins_env.split(',') if origin.strip()]
    else:
        # Fallback seguro para desenvolvimento
        origins = ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:8080']
    
    # SECURITY: Validação rigorosa em produção
    if environment == 'production':
        for origin in origins:
            if origin == '*':
                raise ValueError('SECURITY: Wildcard CORS (*) não permitido em produção')
            if 'localhost' in origin or '127.0.0.1' in origin:
                raise ValueError('SECURITY: Localhost não permitido em CORS de produção')
            if not origin.startswith('https://'):
                raise ValueError(f'SECURITY: Apenas HTTPS permitido em produção. Origem inválida: {origin}')
        
        if not origins:
            raise ValueError('SECURITY: Pelo menos uma origem válida deve ser configurada em produção')
    
    return origins

# ==================== APP INITIALIZATION ====================
app = FastAPI()

# Configurar CORS com validação de segurança
try:
    allowed_origins = get_allowed_origins()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=False,  # SECURITY: Removido para evitar CSRF
        allow_methods=["POST"],  # SECURITY: Apenas métodos necessários
        allow_headers=["Content-Type"],  # SECURITY: Apenas headers necessários
    )
    print(f"✅ CORS configurado com origens: {allowed_origins}")
except ValueError as e:
    print(f"❌ ERRO DE CONFIGURAÇÃO: {e}")
    raise


@app.post("/extract-schedule")
async def extract_schedule(file: UploadFile = File(...)):
    content = await file.read()
    try:
        with pdfplumber.open(io.BytesIO(content)) as pdf:
            if not pdf.pages:
                return JSONResponse(status_code=400, content={"error": "PDF sem páginas."})
            first_page_text = pdf.pages[0].extract_text(x_tolerance=2) or ""
            subjects = parse_subjects_list(first_page_text)
        result = list(subjects.values())
        return JSONResponse({"subjects": result})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": "Falha ao processar o PDF.", "details": str(e)})