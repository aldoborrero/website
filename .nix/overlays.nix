super: prev: {
  tf-custom = prev.terraform.withPlugins (p: [
    p.cloudflare
  ]);
}
