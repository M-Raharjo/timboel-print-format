from pathlib import Path

ROOT = Path(__file__).parent
PARTIALS = ROOT / "partials"
TEMPLATES = ROOT / "templates"
OUT = ROOT / "build"

OUT.mkdir(exist_ok=True)

def read(path):
    return Path(path).read_text(encoding="utf-8")

def inject_partials(text, mapping):
    for key, value in mapping.items():
        text = text.replace(f"[[ {key} ]]", value)
    return text

partials = {
    "styles": read(PARTIALS / "styles.css"),
    "status-banner": read(PARTIALS / "status-banner.html"),
    "header": read(PARTIALS / "header.html"),
    "notes": read(PARTIALS / "notes.html"),
    "totals": read(PARTIALS / "totals.html"),
}

docs = {
    "quotation": "quotation.html",
    "sales-order": "sales-order.html",
    "sales-invoice": "sales-invoice.html",
}

for out_name, template_file in docs.items():
    template_path = TEMPLATES / template_file
    if not template_path.exists():
        continue

    tpl = read(template_path)
    html = inject_partials(tpl, partials)
    (OUT / f"{out_name}.out.html").write_text(html, encoding="utf-8")

print("Build complete.")