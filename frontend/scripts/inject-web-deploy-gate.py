#!/usr/bin/env python3
"""Post-procesa build/web: gate de versión, cache-bust y redirects hash legacy."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INDEX = ROOT / "build" / "web" / "index.html"
BOOTSTRAP = ROOT / "build" / "web" / "flutter_bootstrap.js"


def patch_bootstrap(build_id: str) -> None:
    if not BOOTSTRAP.is_file():
        print(f"WARN: no existe {BOOTSTRAP}", file=sys.stderr)
        return

    bust = f"main.dart.js?v={build_id}"
    text = BOOTSTRAP.read_text(encoding="utf-8")
    text = text.replace('"main.dart.js"', f'"{bust}"')
    text = text.replace("c(\"main.dart.js\")", f'c("{bust}")')
    BOOTSTRAP.write_text(text, encoding="utf-8")
    print(f">> inject-web-deploy-gate: flutter_bootstrap.js cache-bust ({bust})")


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: inject-web-deploy-gate.py BUILD_ID", file=sys.stderr)
        sys.exit(1)

    build_id = sys.argv[1]
    if not INDEX.is_file():
        print(f"ERROR: no existe {INDEX}", file=sys.stderr)
        sys.exit(1)

    gate = f"""  <meta name="botai-build-id" content="{build_id}">
  <script>
    (function () {{
      var BUILD_KEY = 'botai_build_id';
      var BUILD_ID = '{build_id}';

      (function stripDeployQuery() {{
        var u = new URL(location.href);
        if (!u.searchParams.has('_deploy')) return;
        u.searchParams.delete('_deploy');
        history.replaceState(null, '', u.pathname + u.search + u.hash);
      }})();

      function normalizeHash(hash) {{
        if (!hash || hash.charAt(0) !== '#') return hash;
        var qIdx = hash.indexOf('?');
        var path = qIdx === -1 ? hash : hash.slice(0, qIdx);
        var query = qIdx === -1 ? '' : hash.slice(qIdx);
        if (path.length > 2 && path.charAt(path.length - 1) === '/') {{
          path = path.replace(/\\/+$/, '');
        }}
        return path + query;
      }}

      function fixLegacyHash() {{
        var hash = normalizeHash(location.hash || '');
        if (hash !== (location.hash || '')) {{
          location.replace(location.pathname + location.search + hash);
          return true;
        }}
        if (hash.indexOf('#/home/bots') === 0) {{
          location.replace(location.pathname + location.search + '#/bots' + hash.slice('#/home/bots'.length));
          return true;
        }}
        if (hash === '#/home' || hash.indexOf('#/home?') === 0) {{
          location.replace(location.pathname + location.search + '#/agenda/panel' + hash.slice('#/home'.length));
          return true;
        }}
        if (hash.indexOf('#/home/') === 0) {{
          location.replace(location.pathname + location.search + '#/agenda' + hash.slice('#/home'.length));
          return true;
        }}
        return false;
      }}

      function loadFlutter() {{
        var s = document.createElement('script');
        s.src = 'flutter_bootstrap.js?v=' + BUILD_ID;
        s.async = true;
        document.body.appendChild(s);
      }}

      function hardReload(next) {{
        localStorage.setItem(BUILD_KEY, next);
        var reload = function () {{ location.reload(); }};
        if ('caches' in window) {{
          caches.keys().then(function (keys) {{
            return Promise.all(keys.map(function (k) {{ return caches.delete(k); }}));
          }}).finally(reload);
        }} else {{
          reload();
        }}
      }}

      function start() {{
        if (fixLegacyHash()) return;

        fetch('/version.json?t=' + Date.now(), {{ cache: 'no-store' }})
          .then(function (r) {{ return r.ok ? r.json() : null; }})
          .then(function (v) {{
            var next = (v && v.buildId) ? String(v.buildId) : BUILD_ID;
            var prev = localStorage.getItem(BUILD_KEY);
            if (next && prev !== next) {{
              hardReload(next);
              return;
            }}
            if (next) localStorage.setItem(BUILD_KEY, next);
            loadFlutter();
          }})
          .catch(function () {{ loadFlutter(); }});
      }}

      (window.__botaiDeployPrep || Promise.resolve()).then(start);
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
        r'<meta name="botai-build-id"[^>]*>\s*',
        "",
        html,
        flags=re.IGNORECASE,
    )
    html = re.sub(
        r"<script>\s*\(function \(\)[\s\S]*?__botaiDeployPrep[\s\S]*?</script>\s*"
        r"(?=<script>\s*\(function \(\)[\s\S]*?BUILD_KEY[\s\S]*?</script>)",
        "",
        html,
        flags=re.IGNORECASE,
    )
    html = re.sub(
        r"<script>\s*\(function \(\)[\s\S]*?BUILD_KEY[\s\S]*?</script>",
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

    patch_bootstrap(build_id)


if __name__ == "__main__":
    main()
