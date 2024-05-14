#!/bin/bash

cd `dirname $0`

git pull

# https://www.wch-ic.com/products/CH32X035.html
cd datasheet_en
# https://www.wch-ic.com/downloads/CH32X035DS0_PDF.html
wget --continue https://www.wch-ic.com/downloads/file/381.html -O CH32X035DS0.PDF
# https://www.wch-ic.com/downloads/CH32X035RM_PDF.html
wget --continue https://www.wch-ic.com/downloads/file/382.html -O CH32X035RM.PDF
cd ..

cd datasheet_zh
# https://www.wch.cn/downloads/CH32X035DS0_PDF.html
wget --continue https://www.wch-ic.com/downloads/file/443.html -O CH32X035DS0.PDF
# https://www.wch.cn/downloads/CH32X035RM_PDF.html
wget --continue https://www.wch-ic.com/downloads/file/445.html -O CH32X035RM.PDF
cd ..

# https://www.wch.cn/downloads/CH32X035EVT_ZIP.html
wget --continue https://www.wch.cn/downloads/file/444.html -O CH32X035EVT.ZIP
rm -rfv EVT
unzip *.ZIP

git add . --all
git commit -m "update"
git push origin main
