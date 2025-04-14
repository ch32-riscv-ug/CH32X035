#!/bin/bash

cd `dirname $0`

git pull

# https://www.wch-ic.com/products/CH32X035.html
cd datasheet_en
# https://www.wch-ic.com/downloads/CH32X035DS0_PDF.html
curl -z CH32X035DS0.PDF -o CH32X035DS0.PDF https://www.wch-ic.com/downloads/file/381.html
# https://www.wch-ic.com/downloads/CH32X035RM_PDF.html
curl -z CH32X035RM.PDF -o CH32X035RM.PDF https://www.wch-ic.com/downloads/file/382.html
cd ..

cd datasheet_zh
# https://www.wch.cn/downloads/CH32X035DS0_PDF.html
curl -z CH32X035DS0.PDF -o CH32X035DS0.PDF https://www.wch.cn/download/file?id=443
# https://www.wch.cn/downloads/CH32X035RM_PDF.html
curl -z CH32X035RM.PDF -o CH32X035RM.PDF https://www.wch.cn/download/file?id=445
cd ..

# https://www.wch.cn/downloads/CH32X035EVT_ZIP.html
curl -z CH32X035EVT.ZIP -o CH32X035EVT.ZIP https://www.wch.cn/download/file?id=444
rm -rfv EVT
unzip -O GB2312 *.ZIP

git add . --all
git commit -m "update"
git push origin main
