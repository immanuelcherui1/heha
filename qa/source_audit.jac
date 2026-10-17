"""Audit authored source bytes without generated files, dependencies or media.

Run from repository root: jac run qa/source_audit.jac
The report includes tests and QA scripts, and includes CSS in the denominator.
It is a transparent local metric, not a claim about the organisers' tooling.
"""
import json;
import from pathlib { Path }

def audit() -> dict {
    excluded = {".git", ".jac", ".venv", "node_modules", "__pycache__"};
    extensions = {".jac", ".css", ".py", ".js", ".ts", ".jsx", ".tsx", ".sh"};
    files: list[dict] = [];
    jac_bytes = 0; other_bytes = 0;
    for path in sorted(Path(".").rglob("*")) {
        if not path.is_file() or `any(part in excluded for part in path.parts) { continue; }
        if path.suffix not in extensions and path.name != "Makefile" { continue; }
        size = path.stat().st_size;
        if path.suffix == ".jac" { jac_bytes += size; }
        else { other_bytes += size; }
        files.append({"path": str(path), "bytes": size, "language": "Jac" if path.suffix == ".jac" else "CSS" if path.suffix == ".css" else "other"});
    }
    total = jac_bytes + other_bytes;
    percentage = jac_bytes / total * 100 if total else 0.0;
    return {"metric": "authored source file bytes including tests, QA, CSS and Makefile", "jac_bytes": jac_bytes, "other_source_bytes": other_bytes,
            "jac_percent": float(f"{percentage:.2f}"), "meets_local_80_percent_threshold": percentage >= 80,
            "excludes": ["dependencies", "generated files", "documentation", "configuration", "media"], "files": files};
}

with entry:__main__ {
    result = audit();
    Path("docs").mkdir(exist_ok=True);
    Path("docs/source-audit.json").write_text(json.dumps(result, indent=2) + "\n");
    print(f"Jac: {result['jac_percent']}% of authored source bytes ({result['jac_bytes']} Jac bytes).");
    assert result["meets_local_80_percent_threshold"], "Authored source is below 80% Jac by this metric.";
}
