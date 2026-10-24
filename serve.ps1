# Plays the game on this computer: a tiny web server for this folder, then opens the browser.
# Browsers refuse to run a web game straight from a file (file://), so it has to come from a server.
# Close this window to stop it.
param([switch]$NoBrowser)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$types = @{
    ".html" = "text/html; charset=utf-8"; ".js" = "application/javascript"; ".json" = "application/json"
    ".webmanifest" = "application/manifest+json"; ".png" = "image/png"; ".ico" = "image/x-icon"
    ".wasm" = "application/wasm"; ".unityweb" = "application/octet-stream"; ".txt" = "text/plain; charset=utf-8"
}
$listener = New-Object System.Net.HttpListener
$port = 0
foreach ($p in 8090..8110) {
    try { $listener.Prefixes.Clear(); $listener.Prefixes.Add("http://localhost:$p/"); $listener.Start(); $port = $p; break }
    catch { $listener = New-Object System.Net.HttpListener }
}
if ($port -eq 0) { Write-Host "Could not start a local server (ports 8090-8110 busy)."; Read-Host "Press Enter"; exit 1 }
$url = "http://localhost:$port/"
Write-Host "Tank War is running at $url"
Write-Host "Keep this window open while you play. Close it to stop."
if (-not $NoBrowser) { Start-Process $url }
while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $res = $ctx.Response
    try {
        $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart("/"))
        if ($path -eq "") { $path = "index.html" }
        $file = [System.IO.Path]::GetFullPath((Join-Path $root $path))
        if (-not $file.StartsWith($root) -or -not (Test-Path $file -PathType Leaf)) {
            $res.StatusCode = 404
        } else {
            $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
            $res.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
            $res.Headers.Add("Cache-Control", "no-cache")
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        }
    } catch { $res.StatusCode = 500 }
    finally { $res.OutputStream.Close() }
}
