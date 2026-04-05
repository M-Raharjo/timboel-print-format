from pathlib import Path
import re
import sys

ROOT = Path(__file__).parent
PARTIALS = ROOT / "partials"
TEMPLATES = ROOT / "templates"
OUT = ROOT / "build"

OUT.mkdir(exist_ok=True)

def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def load_partials(partials_dir: Path) -> dict[str, str]:
    if not partials_dir.exists():
        print(f"ERROR: partials directory not found: {partials_dir}")
        sys.exit(1)

    partials = {}
    allowed_suffixes = {".html", ".css", ".txt"}

    for path in sorted(partials_dir.iterdir()):
        if not path.is_file():
            continue
        if path.suffix.lower() not in allowed_suffixes:
            continue

        key = path.stem  # e.g. "status-banner" from "status-banner.html"

        if key in partials:
            print(f"ERROR: duplicate partial key '{key}' from file: {path.name}")
            sys.exit(1)

        partials[key] = read(path)

    if not partials:
        print(f"ERROR: no partial files found in {partials_dir}")
        sys.exit(1)

    return partials

def inject_partials(text: str, mapping: dict[str, str]) -> str:
    for key, value in mapping.items():
        text = text.replace(f"[[ {key} ]]", value)
    return text

def fail_on_unresolved_tokens(text: str, source_name: str) -> None:
    leftovers = sorted(set(re.findall(r"\[\[\s*[^][]+?\s*\]\]", text)))
    if leftovers:
        print(f"ERROR: unresolved tokens in {source_name}:")
        for token in leftovers:
            print(f"  - {token}")
        sys.exit(1)

def build_templates() -> None:
    partials = load_partials(PARTIALS)

    template_files = sorted(TEMPLATES.glob("*.html"))
    if not template_files:
        print(f"ERROR: no template files found in {TEMPLATES}")
        sys.exit(1)

    built_any = False

    for template_path in template_files:
        tpl = read(template_path)
        html = inject_partials(tpl, partials)
        fail_on_unresolved_tokens(html, template_path.name)

        out_name = f"{template_path.stem}.out.html"
        out_path = OUT / out_name
        out_path.write_text(html, encoding="utf-8")
        print(f"Built: {out_path}")
        built_any = True

    if not built_any:
        print("ERROR: nothing was built.")
        sys.exit(1)

    print("Build complete.")

if __name__ == "__main__":
    build_templates()