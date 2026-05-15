@echo off
title Monthly Report Dashboard
cd /d "%~dp0"
echo กำลังเปิด Monthly Report Dashboard...
start "" "http://localhost:3000/index.html"
npx --yes serve . --listen 3000
