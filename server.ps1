# Локальный сервер для игры «Тёмные знания».
# Запускается файлом «Запуск игры.bat» (или вручную из этой папки).
# Зачем: Puter.js (движок ИИ-вопросов «Вопрос от DeepSeek») отказывается
# работать со страницами, открытыми как file://, — у файла нет origin.
# На http://localhost всё работает. Сама игра раздаётся из этой папки,
# полностью локально; интернет нужен только для ИИ-вопросов.
$root = $PSScriptRoot
$port = 8765
$mime = @{
  ".html" = "text/html; charset=utf-8";        ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"; ".json" = "application/json; charset=utf-8"
  ".svg"  = "image/svg+xml";                   ".png"  = "image/png"
  ".jpg"  = "image/jpeg";                      ".gif"  = "image/gif"
  ".ico"  = "image/x-icon"
  ".woff" = "font/woff";                       ".woff2" = "font/woff2"
  ".ttf"  = "font/ttf"
  ".mp3"  = "audio/mpeg";                      ".wav"  = "audio/wav"
  ".txt"  = "text/plain; charset=utf-8"
}

$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
try {
  $listener.Start()
} catch {
  Write-Host ""
  Write-Host "  Похоже, сервер уже запущен (порт $port занят) - просто играйте в открытом окне браузера." -ForegroundColor Yellow
  Read-Host "  Нажмите Enter, чтобы закрыть это окно"
  exit 0
}

Write-Host ""
Write-Host "  Игра готова: откройте в браузере http://localhost:$port/index.html" -ForegroundColor Green
Write-Host "  (браузер обычно открывается сам). Не закрывайте это окно, пока игра идёт." -ForegroundColor Gray
Write-Host "  Остановка сервера: Ctrl+C или просто закрыть окно." -ForegroundColor Gray
Write-Host ""

while ($true) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $false, 4096, $true)
    $requestLine = $reader.ReadLine()
    while ($true) { $h = $reader.ReadLine(); if ($null -eq $h -or $h -eq "") { break } }

    if ($requestLine -notmatch '^(GET|HEAD)\s+(\S+)') {
      $body = [System.Text.Encoding]::ASCII.GetBytes("400 Bad Request")
      $head = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 400 Bad Request`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n")
      $stream.Write($head, 0, $head.Length)
      $stream.Write($body, 0, $body.Length)
    } else {
      $path = [System.Uri]::UnescapeDataString($Matches[2])
      if ($path -eq "/") { $path = "/index.html" }
      $rel  = $path.TrimStart('/').Replace('/', '\')
      $file = Join-Path $root $rel
      $full = $null
      try { $full = [System.IO.Path]::GetFullPath($file) } catch {}
      if ($full -and $full.StartsWith($root) -and (Test-Path -LiteralPath $full -PathType Leaf)) {
        $content = [System.IO.File]::ReadAllBytes($full)
        $ext  = [System.IO.Path]::GetExtension($full).ToLower()
        $type = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
        $head = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nContent-Type: $type`r`nContent-Length: $($content.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n")
        $stream.Write($head, 0, $head.Length)
        $stream.Write($content, 0, $content.Length)
      } else {
        $body = [System.Text.Encoding]::UTF8.GetBytes("<h1 style='font-family:sans-serif'>404 - not found</h1>")
        $head = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 404 Not Found`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n")
        $stream.Write($head, 0, $head.Length)
        $stream.Write($body, 0, $body.Length)
      }
    }
  } catch {
    # одиночный сбой запроса не должен ронять сервер
  } finally {
    if ($client) { try { $client.Close() } catch {} }
  }
}
