#!/bin/bash
#
# Download datasheets / EVT archives and extract them.
# データシート / EVT をダウンロードして解凍する。
# Run by GitHub Actions (.github/workflows/update.yml); the workflow does git commit/push.
# GitHub Actions から実行される。git の commit/push はワークフローが行う。
#
# On download failure, exit non-zero instead of overwriting a good file with an
# empty or HTML (404) response, so the Actions job fails.
# ダウンロード失敗時は空ファイルや HTML(404) で上書きせず非ゼロ終了し、ジョブを失敗させる。

set -euo pipefail

cd "$(dirname "$0")"

# fetch <url> <output>
#   --fail        : treat HTTP errors (e.g. 404) as failures
#   temp + verify : download to a temp file, check content, then replace the target
#   reject        : empty responses and non-PDF/ZIP content (e.g. a 404 HTML page)
#   on failure    : return 1; `set -e` aborts the script so the job fails
fetch() {
  local url="$1" out="$2"
  local tmp="${out}.download.$$"
  local code
  echo "Fetching ${out} <- ${url}"
  if ! code=$(curl -fsSL --retry 3 --retry-delay 5 -z "$out" -o "$tmp" -w '%{http_code}' "$url"); then
    echo "ERROR: download failed (curl) for ${url} (http=${code:-?})" >&2
    rm -f "$tmp"
    return 1
  fi
  if [ "$code" = "304" ]; then
    echo "  not modified, keeping existing ${out}"
    rm -f "$tmp"
    return 0
  fi
  if [ ! -s "$tmp" ]; then
    echo "ERROR: empty response from ${url}" >&2
    rm -f "$tmp"
    return 1
  fi
  case "${out,,}" in
    *.pdf)
      if [ "$(head -c 4 "$tmp")" != "%PDF" ]; then
        echo "ERROR: response from ${url} is not a PDF (URL changed?)" >&2
        rm -f "$tmp"
        return 1
      fi
      ;;
    *.zip)
      if [ "$(head -c 2 "$tmp")" != "PK" ]; then
        echo "ERROR: response from ${url} is not a ZIP (URL changed?)" >&2
        rm -f "$tmp"
        return 1
      fi
      ;;
  esac
  mv -f "$tmp" "$out"
  echo "  saved ${out} ($(wc -c < "$out") bytes)"
}

# https://www.wch-ic.com/products/CH32X035.html
cd datasheet_en
# https://www.wch-ic.com/downloads/CH32X035DS0_PDF.html
fetch "https://www.wch-ic.com/download/file?id=381" CH32X035DS0.PDF
# https://www.wch-ic.com/downloads/CH32X035RM_PDF.html
fetch "https://www.wch-ic.com/download/file?id=382" CH32X035RM.PDF
cd ..

cd datasheet_zh
# https://www.wch.cn/downloads/CH32X035DS0_PDF.html
fetch "https://file.wch.cn/download/file?id=443" CH32X035DS0.PDF
# https://www.wch.cn/downloads/CH32X035RM_PDF.html
fetch "https://file.wch.cn/download/file?id=445" CH32X035RM.PDF
cd ..

# https://www.wch.cn/downloads/CH32X035EVT_ZIP.html
fetch "https://file.wch.cn/download/file?id=444" CH32X035EVT.ZIP
rm -rfv EVT
unzip -O GB2312 *.ZIP
