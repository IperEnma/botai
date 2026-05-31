#!/usr/bin/env python3
"""Post-procesa build/web/index.html: gate de versión + cache-bust en bootstrap."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INDEX = ROOT / "build" / "web" / "index.html"


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: inject-web-deploy-gate.py BUILD_ID", file=sys.stderr)
        sys.exit(1)

    build_id = sys.argv[1]
    if not INDEX.is_file():
        print(f"ERROR: no existe {INDEX}", file=sys.stderr)
        sys.exit(1)

    gate = f"""  <script>
    (function () {{
      var BUILD_KEY = 'botai_build_id';
      var BUILD_ID = '{build_id}';
      if ('serviceWorker' in navigator) {{
        navigator.serviceWorker.getRegistrations().then(function (regs) {{
          regs.forEach(function (r) {{ r.unregister(); }});
        }});
      }}
      function loadFlutter() {{
        var s = document.createElement('script');
        s.src = 'flutter_bootstrap.js?v=' + BUILD_ID;
        s.async = true;
        document.body.appendChild(s);
      }}
      fetch('/version.json?t=' + Date.now(), {{ cache: 'no-store' }})
        .then(function (r) {{ return r.ok ? r.json() : null; }})
        .then(function (v) {{
          var next = (v && v.buildId) ? String(v.buildId) : BUILD_ID;
          var prev = localStorage.getItem(BUILD_KEY);
          if (prev && next && prev !== next) {{
            localStorage.setItem(BUILD_KEY, next);
            location.replace(location.href);
            return;
          }}
          if (next) localStorage.setItem(BUILD_KEY, next);
          loadFlutter();
        }})
        .catch(function () {{ loadFlutter(); }});
    }})();
  </script>"""

    html = INDEX.read_text(encoding="utf-8")
    html = re.sub(
        r'<script[^>]*flutter_bootstrap\.js[^>]*>\s*</script>',
        "",
        html,
        flags=re.IGNORECASE,
    )
    html = re.sub(
        r"<script>\s*\(function \(\)[\s\S]*?loadFlutter[\s\S]*?</script>",
        "",
        html,
        flags=re.IGNORECASE,
    )

    if "</body>" not in html:
        print("ERROR: index.html sin </body>", file=sys.stderr)
        sys.exit(1)

    html = html.replace("</body>", gate + "\n</body>", 1)
    INDEX.write_text(html, encoding="utf-8")
    print(f">> inject-web-deploy-gate: index.html (buildId={build_id})")


if __name__ == "__main__":
    main()
