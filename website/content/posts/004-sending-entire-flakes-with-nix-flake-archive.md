---
title: "Sending entire flakes with nix flake archive command"
date: 2023-11-06T17:38:13+01:00
---

![The cyberpunk cat](/images/posts/sending-entire-flakes-with-nix-flake-archive/hero.jpeg)

Nix offers a powerful and flexible tool for package management, including the ability to efficiently copy `closures` between different machines.

A closure in Nix is essentially a container that includes everything needed to build or run a package. There are two types of closures: `build closures`,
which contain all the dependencies necessary to compile the package, including compilers and shell utilities, and `runtime closures`, which cover
everything required to run the package's programs, such as configuration files and dynamically linked libraries.

Unlike file transfer tools like `rsync` or `scp`, which operate on files and directories in a procedural manner, Nix manages complete closures declaratively.
You simply specify 'what' you want to copy, and Nix takes care of the 'how', ensuring that all necessary dependencies are also copied, eliminating the
need to manually manage dependency trees, a process prone to errors.

For example, to copy the famous `hello` application to another machine with Nix installed and run it there, you would write:

```console
$ nix copy --to ssh-ng://my-machine .#hello
```

This command will automatically send all the dependencies necessary to run `hello` on the specified machine with the `--to` argument, using the ssh protocol
(although as a prerequisite the destination machine must have `nix` installed).

But how can we transfer an entire `flake`?

"Flakes" are a feature of `nix` that allows you to define a set of packages and configurations in a reproducible and consistent manner
([here's a guide on Nix flakes](https://zero-to-nix.com/concepts/flakes) if you need more information).

To transfer a complete environment defined by a `flake`, you can use the command `nix flake archive`:

```console
$ nix flake archive --to ssh-ng://my-machine
```

And this way you would have the entire `flake` on `my-machine`! Nice!

If we think carefully, we can take advantage of the previous command to just create a poor's man version of
[colmena-rs](https://github.com/zhaofengli/colmena) or [deploy-rs](https://github.com/serokell/deploy-rs) to update your systems with `nix`.

We can do it as it follows:

```console
$ nix flake archive --to ssh-ng//my-machine --json | jq -r '.path' | wl-copy
```

The above command copies the path of the `flake` on the destination machine to the clipboard (in my case I am using `wayland` so I use `wl-copy`
to copy the path of the flake to the clipboard). To apply the `flake` configuration to the destination machine, you can execute:

```console
$ ssh my-machine 'nixos-rebuild --flake /nix/store/path-to-flake#$(hostname) test'
```

Replace `/nix/store/path-to-flake` with the path obtained from the clipboard. This command rebuilds the NixOS configuration on `my-machine` based
on the specified `flake`.

`nix flake archive` is a [pretty neat command](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-archive) that deserves to be more documented!

See you in my next article 👋🏻!
