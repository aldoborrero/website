super: prev: {
  tf-custom = prev.terraform.withPlugins (p: [
    p.cloudflare
    p.external
    p.hcloud
    p.local
    p.null
    p.random
    p.secret
    p.time
    p.tls
  ]);
}
