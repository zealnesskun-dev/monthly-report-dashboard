@echo off
title Monthly Report Dashboard
cd /d C:\Users\597799\Desktop\claude
echo กำลังเปิด Monthly Report Dashboard...
start "" "http://localhost:3000/Monthly_Report_Single.html"
npx --yes serve . --listen 3000
