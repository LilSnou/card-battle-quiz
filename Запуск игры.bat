@echo off
rem ============================================================
rem  Launcher for "Temnye Znaniya" (Dark Knowledge quiz).
rem  Starts a tiny local server on http://localhost:8765 so that
rem  Puter.js (AI questions from DeepSeek) can work: Puter does
rem  not support pages opened as file:// (no origin).
rem
rem  Play WITHOUT AI questions: just open index.html directly.
rem  Play WITH AI questions: double-click this file instead.
rem  Nothing to install - uses the built-in Windows PowerShell.
rem ============================================================
chcp 65001 >nul
cd /d "%~dp0"
start "" http://localhost:8765/index.html
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
