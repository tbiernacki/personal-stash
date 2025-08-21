// Save as `/etc/proxy.pac`
// Then in KDE -> System Settings -> Network -> Proxy, choose Auto and point to `file:///etc/proxy.pac`

function FindProxyForURL(url, host) {
  // Bypass proxy for localhost and plain hostnames
  if (isPlainHostName(host) || dnsDomainIs(host, "localhost")) return "DIRECT";

  // Try AdGuard HTTP proxy, then SOCKS5, then go DIRECT if unavailable
  return "PROXY 127.0.0.1:3129; SOCKS5 127.0.0.1:1081; DIRECT";
}
