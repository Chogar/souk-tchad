#!/usr/bin/env python3
"""
Déploiement Souk Tchad sur LWS cPanel (FTP + UAPI).

Usage :
  export CPANEL_USER='c2748744c'
  export CPANEL_PASS='votre-mot-de-passe'
  # optionnel :
  export CPANEL_HOST='cpanel.experiencetech-td.com'
  export FTP_HOST='91.234.194.249'   # ou le host FTP LWS
  python3 scripts/deploy-lws.py

Actions :
  1. UAPI — créer sous-domaine apisouktchad (si absent)
  2. FTP  — remplacer le front https://souk.experiencetech-td.com
  3. FTP  — uploader le backend dans ~/souk-tchad/backend
  4. Affiche les étapes Node.js / PostgreSQL restantes dans cPanel
"""
from __future__ import annotations

import os
import ssl
import sys
import zipfile
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path
from ftplib import FTP_TLS, FTP, error_perm

ROOT = Path(__file__).resolve().parents[1]
DEPLOY = ROOT / "deploy"
WEB_ZIP = DEPLOY / "souk-web-latest.zip"
BACKEND_ZIP = DEPLOY / "souk-backend-latest.zip"
ENV_PROD = DEPLOY / ".env.production"

DOMAIN = "experiencetech-td.com"
API_SUB = "apisouktchad"
SOUK_CANDIDATES = [
    "souk",
    "public_html/souk",
    "souk.experiencetech-td.com",
    "public_html/souk.experiencetech-td.com",
]
BACKEND_REMOTE = "souk-tchad/backend"


def require_env(name: str) -> str:
    v = os.environ.get(name, "").strip()
    if not v:
        print(f"❌ Variable manquante : {name}", file=sys.stderr)
        sys.exit(1)
    return v


def uapi(host: str, user: str, password: str, module: str, func: str, **params):
    q = urllib.parse.urlencode(params)
    url = f"https://{host}:2083/execute/{module}/{func}"
    if q:
        url += f"?{q}"
    req = urllib.request.Request(url)
    token = urllib.parse.quote(f"{user}:{password}", safe="")
    req.add_header("Authorization", f"Basic {__import__('base64').b64encode(f'{user}:{password}'.encode()).decode()}")
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, context=ctx, timeout=60) as resp:
        import json

        return json.loads(resp.read().decode())


def ensure_api_subdomain(host: str, user: str, password: str) -> None:
    print(f"→ UAPI : vérifier / créer {API_SUB}.{DOMAIN}")
    try:
        listed = uapi(host, user, password, "SubDomain", "listsubdomains")
        data = listed.get("data") or []
        names = []
        for item in data:
            if isinstance(item, dict):
                names.append(item.get("domain") or item.get("subdomain") or "")
            else:
                names.append(str(item))
        full = f"{API_SUB}.{DOMAIN}"
        if any(API_SUB in n or full in n for n in names):
            print(f"  ✓ Sous-domaine déjà présent ({full})")
            return
        created = uapi(
            host,
            user,
            password,
            "SubDomain",
            "addsubdomain",
            domain=API_SUB,
            rootdomain=DOMAIN,
            dir=f"public_html/{API_SUB}",
        )
        if created.get("status") == 1 or created.get("errors") in (None, []):
            print(f"  ✓ Créé : https://{full}")
        else:
            print(f"  ⚠ Réponse UAPI : {created}")
    except Exception as e:
        print(f"  ⚠ UAPI sous-domaine : {e}")
        print("    → Crée-le manuellement dans cPanel → Domaines → Sous-domaines")


def connect_ftp(host: str, user: str, password: str):
    # Essayer FTPS puis FTP clair
    for cls, label in ((FTP_TLS, "FTPS"), (FTP, "FTP")):
        try:
            ftp = cls(timeout=60)
            ftp.connect(host, 21)
            ftp.login(user, password)
            if isinstance(ftp, FTP_TLS):
                try:
                    ftp.prot_p()
                except Exception:
                    pass
            try:
                ftp.set_pasv(True)
            except Exception:
                pass
            print(f"✓ Connecté en {label} à {host}")
            return ftp
        except Exception as e:
            print(f"  {label} échoué : {e}")
    print("❌ Impossible de se connecter en FTP/FTPS", file=sys.stderr)
    sys.exit(1)


def ftp_cwd_existing(ftp, path: str) -> bool:
    try:
        ftp.cwd(path)
        return True
    except error_perm:
        return False


def find_souk_dir(ftp) -> str:
    start = ftp.pwd()
    for cand in SOUK_CANDIDATES:
        ftp.cwd(start)
        if ftp_cwd_existing(ftp, cand):
            print(f"✓ Dossier front trouvé : {cand}")
            return cand
    # Chercher un dossier contenant index.html nommé souk*
    ftp.cwd(start)
    try:
        names = ftp.nlst()
    except Exception:
        names = []
    for n in names:
        if "souk" in n.lower() and n not in (".", ".."):
            if ftp_cwd_existing(ftp, n):
                print(f"✓ Dossier front trouvé : {n}")
                return n
    print("❌ Dossier du sous-domaine souk introuvable.", file=sys.stderr)
    print("   Indique le chemin avec : export SOUK_FTP_DIR='public_html/souk'", file=sys.stderr)
    sys.exit(1)


def clear_remote_dir(ftp) -> None:
    """Supprime le contenu du dossier FTP courant (fichiers + sous-dossiers)."""

    def wipe(cwd_label: str = "."):
        try:
            entries = []
            ftp.retrlines("LIST", entries.append)
        except Exception:
            return
        for line in entries:
            parts = line.split(maxsplit=8)
            if len(parts) < 9:
                continue
            name = parts[8]
            if name in (".", ".."):
                continue
            is_dir = line.startswith("d")
            if is_dir:
                ftp.cwd(name)
                wipe(name)
                ftp.cwd("..")
                try:
                    ftp.rmd(name)
                except Exception:
                    pass
            else:
                try:
                    ftp.delete(name)
                except Exception:
                    pass

    wipe()


def upload_tree(ftp, local_dir: Path) -> None:
    for path in sorted(local_dir.rglob("*")):
        rel = path.relative_to(local_dir).as_posix()
        if path.is_dir():
            try:
                ftp.mkd(rel)
            except error_perm:
                pass
            continue
        # Créer les dossiers parents
        parent = path.parent.relative_to(local_dir).as_posix()
        if parent and parent != ".":
            parts = parent.split("/")
            cur = ""
            for p in parts:
                cur = f"{cur}/{p}" if cur else p
                try:
                    ftp.mkd(cur)
                except error_perm:
                    pass
        with path.open("rb") as fh:
            ftp.storbinary(f"STOR {rel}", fh)
        print(f"  ↑ {rel}")


def ensure_remote_dirs(ftp, path: str) -> None:
    home = ftp.pwd()
    for part in path.strip("/").split("/"):
        try:
            ftp.mkd(part)
        except error_perm:
            pass
        ftp.cwd(part)
    ftp.cwd(home)


def main() -> None:
    user = require_env("CPANEL_USER")
    password = require_env("CPANEL_PASS")
    cpanel_host = os.environ.get("CPANEL_HOST", "cpanel.experiencetech-td.com").strip()
    ftp_host = os.environ.get("FTP_HOST", "91.234.194.249").strip()

    if not WEB_ZIP.is_file() or not BACKEND_ZIP.is_file():
        print("❌ Paquets manquants dans deploy/. Relance le build d’abord.", file=sys.stderr)
        sys.exit(1)

    ensure_api_subdomain(cpanel_host, user, password)

    ftp = connect_ftp(ftp_host, user, password)
    home = ftp.pwd()
    print(f"  FTP home = {home}")

    # --- Front web ---
    souk_dir = os.environ.get("SOUK_FTP_DIR", "").strip() or find_souk_dir(ftp)
    ftp.cwd(home)
    ftp.cwd(souk_dir)
    print(f"→ Nettoyage de {souk_dir} …")
    clear_remote_dir(ftp)
    print("→ Upload front web …")
    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(WEB_ZIP) as zf:
            zf.extractall(tmp)
        upload_tree(ftp, Path(tmp))
    print("✓ Front déployé → https://souk.experiencetech-td.com/")

    # --- Backend ---
    ftp.cwd(home)
    print(f"→ Upload backend → {BACKEND_REMOTE}")
    ensure_remote_dirs(ftp, BACKEND_REMOTE)
    ftp.cwd(BACKEND_REMOTE)
    # vider partiellement (garder uploads si existe)
    try:
        names = ftp.nlst()
    except Exception:
        names = []
    for n in names:
        if n in (".", "..", "uploads", "node_modules", "dist"):
            continue
        try:
            ftp.delete(n)
        except Exception:
            pass
    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(BACKEND_ZIP) as zf:
            zf.extractall(tmp)
        # Renommer .env.production → .env si présent
        env_src = Path(tmp) / ".env.production"
        if env_src.exists():
            env_src.rename(Path(tmp) / ".env")
        elif ENV_PROD.exists():
            (Path(tmp) / ".env").write_bytes(ENV_PROD.read_bytes())
        upload_tree(ftp, Path(tmp))
    print("✓ Backend uploadé → ~/souk-tchad/backend")

    try:
        ftp.quit()
    except Exception:
        pass

    print(
        """
═══════════════════════════════════════════════════════════
Upload terminé. Reste à faire DANS cPanel (une fois) :
═══════════════════════════════════════════════════════════
1. Domaines → SSL pour apisouktchad.experiencetech-td.com
2. PostgreSQL → vérifier base c2748744c_souktchad + user
   → mettre DATABASE_PASSWORD dans ~/souk-tchad/backend/.env
3. Setup Node.js App → Create :
   - Root : souk-tchad/backend
   - URL  : apisouktchad.experiencetech-td.com
   - File : dist/main.js
   - Node : 20+
4. Terminal cPanel :
   cd ~/souk-tchad/backend
   bash scripts/cpanel-run.sh npm ci
   bash scripts/cpanel-run.sh npm run build
   bash scripts/cpanel-db-init.sh
5. Restart l’app Node.js
6. Test : https://apisouktchad.experiencetech-td.com/api/categories
═══════════════════════════════════════════════════════════
"""
    )


if __name__ == "__main__":
    main()
