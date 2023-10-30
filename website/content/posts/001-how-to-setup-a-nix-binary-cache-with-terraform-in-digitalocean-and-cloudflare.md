---
author: Aldo Borrero
date: 2022-11-25
title: How to set up a Nix Binary cache with Terraform in DigitalOcean + Cloudflare
aliases:
  - /posts/how-to-setup-a-nix-binary-cache-with-terraform-in-digitalocean-and-cloudflare/
---

![The Future](/images/posts/how-to-setup-a-nix-binary-cache-with-terraform-in-digitalocean-and-cloudflare/future.webp)

As the name implies, a Nix binary cache allows you to have the result of building packages handy so that it can be used by other machines (or yours) directly instead of building the same packages over and over.

This post won't extend into explaining what a binary cache is and why it's necessary when working with [Nix and Nixos](https://nixos.org). Others have done it quite nicely.

What it will cover, though, is proper instructions to have one ready to be used with [DigitalOcean Spaces + CDN](https://www.digitalocean.com/products/spaces), [Cloudflare](https://www.cloudflare.com/) with a custom domain using [Terraform](https://www.terraform.io/), as most articles are focused towards the AWS S3 ecosystem.

DigitalOcean offers its Spaces product which is its version of AWS S3, and knowing and acknowledging some limitations ([primarily related to individual keys per bucket](https://www.digitalocean.com/community/questions/spaces-different-keys-per-bucket) 😱), their pricing seems quite fair to me. You may end up with an approximate cost of 5$ per month for the following:

- **Storage**: 250 GiB
- **Outbound transfer** : 1 TiB
- **Additional storage**: $0.02/GiB
- **Additional transfer**: $0.01/GiB

Even if you surpass those limits by far, it won't cost you a lung 👏🏻!

The rest of the post will be divided into three sections:

1. Setting up the S3 storage in DigitalOcean Spaces.
1. Configuring Cloudflare to use your custom domain.
1. Conclusions

Let's get our hands dirty at work 💪🏻!

Pst! If you want the TLDR, [go to my Gist with the complete source code ready to be used](https://gist.github.com/aldoborrero/d77d4744c68bb14395d4bf17b5d829a7)!

## Setting up the S3 storage in DigitalOcean Spaces

```terraform
resource "digitalocean-spaces-bucket" "nix-store" {
  name   = "nix-store"
  region = "fra1"
  acl    = "private"

  lifecycle-rule {
    id                                     = "ttl"
    enabled                                = true
    abort-incomplete-multipart-upload-days = 1
    expiration {
      days = 30
    }
  }

  versioning {
    enabled = true
  }
}
```

As you can see, nothing from above is rocket science engineering.

I do recommend, though, setting up a sane `expiration` rule to expire objects with more than 30 days. That way, you can save up space, and, as today's computers are fast enough, you can always reconstitute those specific objects quite easily.

I also enabled versioning just in case, for whatever reason, I remove something and want to revert to a different version, but it's not that necessary.

Next, we need to configure the S3 bucket to allow anonymous reads [the Nix manual includes information related to this matter](https://nixos.org/manual/nix/stable/package-management/s3-substituter.html#anonymous-reads-to-your-s3-compatible-binary-cache):

```terraform
resource "digitalocean-spaces-bucket-policy" "nix-cache-anonymous-reads" {
  region = digitalocean-spaces-bucket.nix-store.region
  bucket = digitalocean-spaces-bucket.nix-store.name
  policy = jsonencode({
    "Id" : "DirectReads",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowDirectReads",
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketLocation"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${digitalocean-spaces-bucket.nix-store.name}",
          "arn:aws:s3:::${digitalocean-spaces-bucket.nix-store.name}/*"
        ],
        "Principal" : "*"
      }
    ]
  })
}
```

And last but not least, in this section, we need to add a special entry to our Nix Binary cache:

```terraform
resource "digitalocean-spaces-bucket-object" "nix-cache-info" {
  region       = digitalocean-spaces-bucket.nix-store.region
  bucket       = digitalocean-spaces-bucket.nix-store.name
  content-type = "text/html"
  key          = "nix-cache-info"
  content      = <<EOF
StoreDir: /nix/store
WantMassQuery: 1
Priority: 10
EOF
}
```

At the very top of each Nix Binary cache, there's always a `/nix-cache-info` file that nix always looks for to treat the endpoint as a binary cache. If, for example, we query `https://cache.nixos.org` (the mother of all binary caches):

```sh
curl -I https://cache.nixos.org/nix-cache-info
```

We obtain the following response:

```bash
StoreDir: /nix/store
WantMassQuery: 1
Priority: 40
```

Dissecting the meaning of the file, we find the following entries:

- `StoreDir` is a field you wouldn't normally touch as, in general, by default, nix stores its derivations at path `/nix/store/${hash}`.
- `WantMassQuery` is a [specifc boolean](https://github.com/NixOS/nix/blob/04e74f7c8bb5589dec578dd049013d3cd2554e65/src/libstore/store-api.hh#L109) setting that allows controlling if this binary cache can be queried efficiently (I still need to dig into [this deeply in the source code to know exactly the implications](https://github.com/NixOS/nix/issues/1503)).
- `Priority`, as the name suggests, will set the priority compared to other binary caches; the lower the number, the higher the priority.

And with this, we have finished our setup for the S3 settings in DigitalOcean Spaces. You can use this directly without having to rely on the Cloudflare part, but we can do better.

## Configure your domain with Cloudflare

This part is a little bit more involved (but not that much, trust me!). Here the main objective we have is to:

First, what we want to do is to [configure Terraform to generate a custom origin certificate](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/) that Cloudflare can use to communicate directly between their serves and with the DigitalOcean Spaces. To do so, we can use the `tls` provider (bear in mind that the `tls` provider stores sensitive information in the [Terraform State](https://developer.hashicorp.com/terraform/language/state/sensitive-data) directly, so consider switching to using [Vault](https://registry.terraform.io/providers/hashicorp/vault/latest/docs) provider or even the [SOPS](https://registry.terraform.io/providers/carlpett/sops/latest/docs) one. Or modify to provision your own directly without storing private keys!):

```terraform
resource "tls-private-key" "nix-store-origin-key" {
  algorithm = "RSA"
  rsa-bits  = 2048
}
```

The next step is to properly craft a [certificate signing request](https://en.wikipedia.org/wiki/Certificate-signing-request), like below (modify the common name to match the domain you plan to use for the binary cache and also as well the other options):

```terraform
resource "tls-cert-request" "nix-store-origin-cert" {
  private-key-pem = tls-private-key.nix-store-origin-key.private-key-pem

  subject {
    common-name  = "cache.example.com"
    organization = "My Organization, LTD"
    country      = "USA"
    locality     = "Los Angeles"
  }
}
```

With that, we can then ask Cloudflare to create our certificate (you can customize how long the certificate should be valid):

```terraform
resource "cloudflare-origin-ca-certificate" "nix-store-origin-cert" {
  # See: https://github.com/cloudflare/terraform-provider-cloudflare/issues/1919#issuecomment-1270722657
  provider = cloudflare.cf-user-service-auth

  csr                = tls-cert-request.nix-store-origin-cert.cert-request-pem
  hostnames          = ["cache.example.com"]
  request-type       = "origin-rsa"
  requested-validity = 365
}
```

We then proceed to store the certificate inside DigitalOcean:

```terraform
resource "digitalocean-certificate" "nix-store-origin-cert" {
  name             = "cf-origin-cert"
  type             = "custom"
  private-key      = tls-private-key.nix-store-origin-key.private-key-pem
  leaf-certificate = cloudflare-origin-ca-certificate.nix-store-origin-cert.certificate
}
```

We enable the DigitalOcean CDN:

```terraform
resource "digitalocean-cdn" "nix-store-cdn" {
  origin           = digitalocean-spaces-bucket.nix-store.bucket-domain-name
  certificate-name = digitalocean-certificate.nix-store-origin-cert.name
  custom-domain    = "cache.example.com"
}
```

With this, then we can proceed to register our domain within Cloudflare:

```terraform
data "cloudflare-zone" "domain" {
  name = "example.com"
}

resource "cloudflare-record" "nix-store-cache" {
  name    = "cache"
  value   = digitalocean-cdn.nix-store-cdn.endpoint
  type    = "CNAME"
  ttl     = 1 # Auto
  proxied = true
  zone-id = data.cloudflare-zone.domain.id
}
```

Voilá! Your Nix binary cache is ready to rock with a custom subdomain and managed with Terraform! 😁👏🏻💃

## Conclusions

Creating a Nix binary cache is a very easy process once you know how to do it properly! And very fun! It also gives you the power to control your data and your infrastructure!

As I mentioned at the beginning of the article, [this Gist contains everything in one place and ready to be used](https://gist.github.com/aldoborrero/d77d4744c68bb14395d4bf17b5d829a7)!

If you want to expand more knowledge related to the Nix binary cache, I would recommend reading the following:

- [A Nix Binary Cache Specification](https://fzakaria.com/2021/08/12/a-nix-binary-cache-specification.html).
- [Serving a Nix Store via S3](https://nixos.org/manual/nix/stable/package-management/s3-substituter.html).
- [Setting up a private nix cache for fun and profit](https://www.channable.com/tech/setting-up-a-private-nix-cache-for-fun-and-profit).
- [Nix Wiki: Binary Cache entry](https://nixos.wiki/wiki/Binary-Cache).
- [Nix's source code implementation of the binary cache store](https://github.com/NixOS/nix/blob/b3d2a05c59266688aa904d5fb326394cbb7e9e90/src/libstore/binary-cache-store.cc).

See you in the next post 👋🏻!
