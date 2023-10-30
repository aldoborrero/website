---
author: Aldo Borrero
date: 2023-01-15
title: 'Setting up my machines: nix style'
aliases: [/posts/setting-up-my-machines-nix-style/]
---

![The Technology](/images/posts/setting-up-my-machines-nix-style/cover.jpeg)

A couple of weeks ago, my friend Brian wrote an excellent article called: "[Setting up my new laptop: nix style](https://bmcgee.ie/posts/2022/12/setting-up-my-new-laptop-nix-style/)" in which he explains a superb way of installing Nix with a USB stick, trying to automate the process as much as possible. He describes the following:

- How to create a bootable customized ISO that can be installed on a USB stick.
- How to take advantage of [Disko](https://github.com/nix-community/disko) for automatic disk partitioning.
- How to build the system closure locally and use `nix copy` to transfer via SSH the image to the USB stick.

If you're curious, I do recommend you to have a read at it. I'm pretty sure you'll learn a couple of things! This article is based on his but with a few tweaks to automate the process, removing as much as possible any manual steps.

[I have prepared a `nix template`](https://github.com/aldoborrero/templates/tree/main/templates/blog/nix/setting-up-machines-nix-style) that captures the ideas written here so you can easily use it as your starting point.

So, let's continue our quest of:

![Nix all the things!](/images/posts/setting-up-my-machines-nix-style/nix-all-the-things.jpg)

(Sorry, Brian, I stole your picture! 😉)

**Note**: I assume the reader has enough knowledge of `nix` and `nix flakes` to follow the content below.

## Create your flake with flake.parts

[`flake.parts`](https://flake.parts/) is my newest addition to my `nix` toolbelt since I got introduced to it by Jonas Chevalier ([@zimbatm](https://twitter.com/zimbatm))! You may wonder what the hell is `flake.parts`? And why is it so valuable?

The project describes itself as follows:

> flake-parts provides the options that represent standard flake attributes and establishes a way of working with system. Opinionated features are provided by an ecosystem of modules that you can import.

Explained it simply: it allows you to compose your `flake` attributes by reusing as much functionality from other people quite easily. And that's very powerful! Trust me! Do you want to see it by yourself?

Let's then craft a [`flake.nix`](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/flake.nix) file with the following content:

```nix
{
  description = "How to flash a Nixos USB image the Nix way!";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # packages
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;

    # flake-parts
    flake-parts = {
      url = github:hercules-ci/flake-parts;
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-root.url = github:srid/flake-root;
    mission-control.url = github:Platonic-Systems/mission-control;

    # utilities
    nixos-generators = {
      url = github:nix-community/nixos-generators;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = github:numtide/treefmt-nix;
    disko = {
      url = github:nix-community/disko;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = inputs @ {
    flake-parts,
    flake-root,
    mission-control,
    nixpkgs,
    treefmt-nix,
    ...
  }: let
    # Use our custom lib enhanced with nixpkgs and hm one
    lib = import ./nix/lib {lib = nixpkgs.lib;} // nixpkgs.lib;
  in
    (flake-parts.lib.evalFlakeModule
      {
        inherit inputs;
        specialArgs = {inherit lib;};
      }
      {
        debug = false;
        imports = [
          treefmt-nix.flakeModule
          flake-root.flakeModule
          mission-control.flakeModule
          ./nix
          ./nixos
        ];
        systems = ["x86-64-linux"];
        perSystem = {inputs', ...}: {
          # make pkgs available to all `perSystem` functions
          -module.args.pkgs = inputs'.nixpkgs.legacyPackages;
          # make custom lib available to all `perSystem` functions
          -module.args.lib = lib;
        };
      })
    .config
    .flake;
}
```

Wow, that chunk of `nix` was intense! Isn't it? Don't worry! Let's explain it step by step.

Let's start with the `inputs`:

```nix
inputs = {
    # packages
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;

    # flake-parts
    flake-parts = {
      url = github:hercules-ci/flake-parts;
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-root.url = github:srid/flake-root;
    mission-control.url = github:Platonic-Systems/mission-control;

    # utilities
    nixos-generators = {
      url = github:nix-community/nixos-generators;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = github:numtide/treefmt-nix;
    disko = {
      url = github:nix-community/disko;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
}
```

As you can see above, the `inputs` are divided into three main sections:

- **packages**: This is the regular `nixpkgs` that you plan to use in your flake, nothing special here.
- **flake-parts**: It imports the `flake.parts` framework alongside two useful modules:
  - [**flake-root**](https://github.com/srid/flake-root): A little `flake.parts` module that allows finding your project root.
  - [**mission-control**](https://flake.parts/options/mission-control.html): This `flake.parts` module allows composing custom scripts that will run on your repository root. It will become handy for automating repetitive commands.
- **utilities**: As the name implies, a different set of tools.
  - [**nixos-generators**](https://github.com/nix-community/nixos-generators): A collection of utilities to generate `nixos` images in other formats. With this tool, we can easily customize our USB image.
  - [**treefmt-nix**](https://github.com/numtide/treefmt-nix): A flake utility that provides [`treefmt`](https://github.com/numtide/treefmt) and adds a `flake.parts` module to easily format my entire source code.
  - [**disko**](https://github.com/nix-community/disko): This utility allows to format and partition your disk automatically.
  - [**nixos-hardware**](https://github.com/NixOS/nixos-hardware): A collection of NixOS modules that covers common hardware quirks for available machines.

Now let's move on to the `outputs` part:

```nix
outputs = inputs @ {
    flake-parts,
    flake-root,
    mission-control,
    nixpkgs,
    treefmt-nix,
    ...
  }: let
    # Use our custom lib enhanced with nixpkgs and hm one
    lib = import ./nix/lib {lib = nixpkgs.lib;} // nixpkgs.lib;
  in
    (flake-parts.lib.evalFlakeModule
      {
        inherit inputs;
        specialArgs = {inherit lib;};
      }
      {
        debug = false;
        imports = [
          treefmt-nix.flakeModule
          flake-root.flakeModule
          mission-control.flakeModule
          ./nix
          ./nixos
        ];
        systems = ["x86-64-linux"];
        perSystem = {inputs', ...}: {
          # make pkgs available to all `perSystem` functions
          -module.args.pkgs = inputs'.nixpkgs.legacyPackages;
          # make custom lib available to all `perSystem` functions
          -module.args.lib = lib;
        };
      })
    .config
    .flake;
```

Here we use `flake.parts` to configure and craft our `nix flake` outputs. We can mention the following:

- We import a customized version of `nixpkgs.lib` with extra functions that I added.
- We have a `./nix` folder dedicated to my `flake.parts` modules.
- We have a `./nixos` folder where our different systems will live.

Thanks to `mission-control`, I can type the following:

```bash
$ ,
```

And this menu will appear on the terminal:

```bash
Available commands:

## Dev Tools

  , fmt  : Format the source tree

## Images

  , flash-nuc-iso  : Flash installer-iso image for NUC-1

## Nix

  , nix-build-nuc  : Builds toplevel NixOS image for NUC-1 host

## Utils

  , clean   : Cleans any result produced by Nix or associated tools
  , run-vm  : Executes a VM if output derivation contains one
```

As a result, I can have shortcuts for the most common things I would like to do on my `nix flake`. For example, if I type:

```bash
$ , flash-nuc-iso
```

It will start creating the customized NixOS USB installer image of the system (in my case, an Intel NUC), and it will flash it automatically to a plugged USB! It even allows me to select on which USB I want to flash it:

![Mission Control with a custom command](/images/posts/setting-up-my-machines-nix-style/mission-control-flash-usb-menu.png)

This is very neat, as I don't need to remember the usual commands with `dd` and similar. Instead, the knowledge is captured inside a script, and I can go as fancy as I want with `nix`. Below you can see the definition inside [`nix/scripts.nix`](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/nix/scripts.nix):

```nix
{
  perSystem = {
    self',
    pkgs,
    ...
  }: let
    flash-iso-image = name: image: let
      pv = "${pkgs.pv}/bin/pv";
      fzf = "${pkgs.fzf}/bin/fzf";
    in
      pkgs.writeShellScriptBin name ''
        set -euo pipefail

        # Build image
        nix build .#${image}

        # Display fzf disk selector
        iso="./result/iso/"
        iso="$iso$(ls "$iso" | ${pv})"
        dev="/dev/$(lsblk -d -n --output RM,NAME,FSTYPE,SIZE,LABEL,TYPE,VENDOR,UUID | awk '{ if ($1 == 1) { print } }' | ${fzf} | awk '{print $2}')"

        # Format
        ${pv} -tpreb "$iso" | sudo dd bs=4M of="$dev" iflag=fullblock conv=notrunc,noerror oflag=sync
      '';
  in {
    mission-control.scripts = {
      # ISOs
      flash-nuc-1-iso = {
        category = "Images";
        description = "Flash installer-iso image for NUC-1";
        exec = flash-iso-image "flash-nuc-iso" "nuc-1-iso-image";
      };
    };
  };
}
```

At this point, I do recommend visiting my template and having a look at how things are organized! Also, if you have recommendations or improvements, I would like to hear them!

## Create your regular configuration for your system

Following the previous section, you can now define a NixOS configuration system for your specific machine. For example, in my template, inside the [`nixos/default.nix`](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/nixos/default.nix) file, I have defined a `nuc-1` machine with the following `flake.parts` module configuration:

```nix
{
  self,
  inputs,
  lib,
  ...
}: let
  inherit
    (self.inputs)
    disko
    flake-registry
    impermanence
    nixos-hardware
    nixpkgs
    ;

  nixosSystem = args:
    (lib.makeOverridable lib.nixosSystem)
    (lib.recursiveUpdate args {
      modules =
        args.modules
        ++ [
          {
            config.nixpkgs.pkgs = lib.mkDefault args.pkgs;
            config.nixpkgs.localSystem = lib.mkDefault args.pkgs.stdenv.hostPlatform;
          }
        ];
    });

  hosts = lib.rakeLeaves ./hosts;
  modules = lib.rakeLeaves ./modules;

  defaultModules = [
    # make flake inputs accessible in NixOS
    {
      -module.args.self = self;
      -module.args.inputs = inputs;
    }
    # load common modules
    ({...}: {
      imports = [
        impermanence.nixosModules.impermanence
        disko.nixosModules.disko

        modules.i18n
        modules.minimal-docs
        modules.nix
        modules.openssh
        modules.pgweb
        modules.server
        modules.tailscale
      ];
    })
  ];

  pkgs.x86-64-linux = import nixpkgs {
    inherit lib;
    system = "x86-64-linux";
    config.allowUnfree = true;
  };
in {
  imports = [
    ./images
  ];

  flake.nixosConfigurations = {
    nuc-1 = nixosSystem {
      pkgs = pkgs.x86-64-linux;
      modules =
        defaultModules
        ++ [nixos-hardware.nixosModules.intel-nuc-8i7beh]
        ++ [
          modules.serial-console
          modules.tcp-hardening
          modules.tcp-optimizations
          modules.tmpfs
          modules.fs-trim
        ]
        ++ [hosts.nuc-1];
    };
  };
}
```

As you can see above, there are some standard modules and utilities that I want to reuse on other machines, so I import them and add those to each machine individually.

Now in the terminal, if I type `nix build .#nixosConfigurations.nuc-1.config.system.build.toplevel` it will produce the `toplevel` system closure for the `nuc-1` machine. But again, I can take advantage of `mission-control` to create another shorcut:

```nix

{
  perSystem = {
    self',
    pkgs,
    ...
  }: {
    mission-control.scripts = {
      nix-build-nuc = {
        category = "Nix";
        description = "Builds toplevel NixOS image for NUC-1 host";
        exec = pkgs.writeShellScriptBin "nix-build-nuc" ''
          set -euo pipefail
          nix build .#nixosConfigurations.nuc-1.config.system.build.toplevel
        '';
      };
    };
  };
}
```

And now I need to type `, nix-build-nuc`!

## Create a generic installable ISO

The idea in this part is quite simplistic: we can take advantage of [`nixos-generators`](https://github.com/nix-community/nixos-generators) to create a customized installer that we can later flash onto a USB drive. The skeleton could be defined as follows (you can find it defined on [`./nixos/default.nix`](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/nixos/default.nix)):

```nix
{
  self,
  inputs,
  ...
}: {
  perSystem = {
    self',
    pkgs,
    ...
  }: let
    inherit (inputs) nixos-generators;

    defaultModule = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./base-iso.nix
      ];
      -module.args.self = self;
      -module.args.inputs = inputs;
    };
  in {
    packages = {
      iso-image = nixos-generators.nixosGenerate {
        inherit pkgs;
        format = "install-iso";
        modules = [
          defaultModule
        ];
      };
    };
  };
}
```

The file [`./base-iso.nix`](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/nixos/images/base-iso.nix) contains a set of utilities that I want to be installed on my USB NixOS installer image. It also includes a list of SSH keys I allow to have remote access:

```nix
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mapAttrs' nameValuePair mkForce;
in {
  environment.systemPackages = with pkgs; [
    helix
    vim
    curl
    wget
    httpie
    diskrsync
    partclone
    ntfsprogs
    ntfs3g
  ];

  # Use helix as the default editor
  environment.variables.EDITOR = "hx";

  networking = {
    firewall.enable = false;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    usePredictableInterfaceNames = false;
  };

  services.resolved.enable = false;

  systemd = {
    network.enable = true;
    network.networks =
      mapAttrs'
      (num: -:
        nameValuePair "eth${num}" {
          extraConfig = ''
            [Match]
            Name = eth${num}
            [Network]
            DHCP = both
            LLMNR = true
            IPv4LL = true
            LLDP = true
            IPv6AcceptRA = true
            IPv6Token = ::521a:c5ff:fefe:65d9
            # used to have a stable address for zfs send
            Address = fd42:4492:6a6d:43:1::${num}/64
            [DHCP]
            UseHostname = false
            RouteMetric = 512
          '';
        })
      {
        "0" = {};
        "1" = {};
        "2" = {};
        "3" = {};
      };
    services.update-prefetch.enable = false;
    services.sshd.wantedBy = mkForce ["multi-user.target"];
  };

  documentation = {
    enable = false;
    nixos.options.warningsAreErrors = false;
    info.enable = false;
  };

  nix = {
    gc.automatic = true;

    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      flake-registry = ${inputs.flake-registry}/flake-registry.json
    '';

    nixPath = [
      "nixpkgs=${pkgs.path}"
    ];
  };

  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHXBP3u/XWr7fwix5lVixsAlfBNGK06aCVVQ9sRJOBCZAAAAGnNzaDphbGRvYm9ycmVyb0BnaXRodWIuY29t ssh:aldoborrero@github.com"
  ];

  system.stateVersion = "23.05";
}
```

So far, so good! At this point, we can easily create a generic ISO image that we can flash on a USB drive and later go to any machine, wait for it to boot, grab the IP address to connect to it remotely, and transfer the system `toplevel` image with `nix copy`, just as Brian described in his article!

But what if I told you we could do it in another way? One where it automatically flashes your machine drives with `disko` and installs the system directly on your target machine? Keep reading!

## Create the disk layout with Disko

With [`disko`](https://github.com/nix-community/disko/) we can define with `nix` how your machine's disks will partition automatically. It's pretty neat and supports a wide range of different filesystems! For example, for my `nuc-1` machine I do have the following:

```nix
{...}: {
  disko.devices = {
    disk.nvme = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "ESP";
            type = "partition";
            start = "1MiB";
            end = "512MiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "root";
            type = "partition";
            start = "512MiB";
            end = "100%";
            bootable = true;
            part-type = "primary";
            content = {
              type = "btrfs";
              extraArgs = "-f";
              mountpoint = "/";
              mountOptions = ["discard" "noatime"];
              subvolumes = {
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd"];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          }
        ];
      };
    };
    disk.sda = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "data";
            type = "partition";
            start = "1MiB";
            end = "100%";
            content = {
              type = "btrfs";
              extraArgs = "-f";
              mountpoint = "/data";
              mountOptions = ["discard" "noatime"];
              subvolumes = {
                "/ethereum" = {
                  mountpoint = "/ethereum";
                  mountOptions = ["discard" "noatime" "nodatacow"];
                };
              };
            };
          }
        ];
      };
    };
  };
}
```

This file describes how my machine will be partitioned. But do you know that `disko` has an option called [`enableConfig`](https://github.com/nix-community/disko/blob/d4ad9595432959440984b2ba33064cfe3399d0e3/module.nix#L12)? The docs say the following:

```text
configure nixos with the specified devices
should be true if the system is booted with those devices
should be false on an installer image etc.
```

Mmmm... 🤔 Can I somehow incorporate `disko` into my installer image? Yes, you can! If [we inspect the implementation closely](https://github.com/nix-community/disko/blob/d4ad9595432959440984b2ba33064cfe3399d0e3/module.nix#L22):

```nix
config = lib.mkIf (cfg.devices.disk != {}) {
  system.build.formatScript = pkgs.writers.writeDash "disko-create" ''
    export PATH=${lib.makeBinPath (types.diskoLib.packages cfg.devices pkgs)}:$PATH
    ${types.diskoLib.create cfg.devices}
  '';

  system.build.mountScript = pkgs.writers.writeDash "disko-mount" ''
    export PATH=${lib.makeBinPath (types.diskoLib.packages cfg.devices pkgs)}:$PATH
    ${types.diskoLib.mount cfg.devices}
  '';

  system.build.disko = pkgs.writers.writeBash "disko" ''
    export PATH=${lib.makeBinPath (types.diskoLib.packages cfg.devices pkgs)}:$PATH
    ${types.diskoLib.zapCreateMount cfg.devices}
  '';

  # This is useful to skip copying executables uploading a script to an in-memory installer
  system.build.diskoNoDeps = pkgs.writeScript "disko" ''
    #!/usr/bin/env bash
    ${types.diskoLib.zapCreateMount cfg.devices}
  '';

  # Remember to add config keys here if they are added to types
  fileSystems = lib.mkIf cfg.enableConfig (lib.mkMerge (lib.catAttrs "fileSystems" (types.diskoLib.config cfg.devices)));
  boot = lib.mkIf cfg.enableConfig (lib.mkMerge (lib.catAttrs "boot" (types.diskoLib.config cfg.devices)));
  swapDevices = lib.mkIf cfg.enableConfig (lib.mkMerge (lib.catAttrs "swapDevices" (types.diskoLib.config cfg.devices)));
};
```

That means I can incorporate `disko` into my bootable USB stick! It will also include the necessary scripts to `format` and `mount` directly my `nuc-1` machine!

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  # disko
  disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.disko}'';
  disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
  disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";
in {
  imports = [
    ../hosts/nuc-1/disko.nix # The partioning definition (showcased above)
  ];

  # we don't want to generate filesystem entries on this image
  disko.enableConfig = lib.mkDefault false;

  # add disko commands to format and mount disks
  environment.systemPackages = [
    disko
    disko-mount
    disko-format
  ];
}
```

So, that means whenever I'm booted into the installer image, I can type `disko-format` for formatting the disks and later to `disko-mount` to mount them.

## Create a custom install script

In nix, everything is a derivation! So, maybe if we have included `disko` in our installable image, we can do the same by copying directly the `toplevel` closure, right? Yes! We can! And we can take advantage and write a custom `install-system` script that installs the system directly like below:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  # disko
  disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.disko}'';
  disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
  disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";

  # system
  system = self.nixosConfigurations.nuc-1.config.system.build.toplevel;

  install-system = pkgs.writeShellScriptBin "install-system" ''
    set -euo pipefail

    echo "Formatting disks..."
    . ${disko-format}/bin/disko-format

    echo "Mounting disks..."
    . ${disko-mount}/bin/disko-mount

    echo "Installing system..."
    nixos-install --system ${system}

    echo "Done!"
  '';
in {
  imports = [
    ../hosts/nuc-1/disko.nix
  ];

  # we don't want to generate filesystem entries on this image
  disko.enableConfig = lib.mkDefault false;

  # add disko commands to format and mount disks
  environment.systemPackages = [
    disko
    disko-mount
    disko-format
    install-system
  ];
}
```

Now, I can write my bootable USB image disk customized for each machine, boot it into the machine, and type `install-system` (locally or remotely). It will automatically install the system on the device. Boom! How cool is that? 😃

## Create a device specifc installable ISO

If we zoom out, then my custom installer for `nuc-1` looks like this (you can find it on the template inside [`./nixos/images/default.nix`](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/nixos/images/default.nix)):

```nix
{
  self,
  inputs,
  ...
}: {
  perSystem = {
    self',
    pkgs,
    ...
  }: let
    inherit (inputs) nixos-generators;

    defaultModule = {...}: {
      imports = [
        inputs.disko.nixosModules.disko
        ./base-iso.nix
      ];
      -module.args.self = self;
      -module.args.inputs = inputs;
    };
  in {
    packages = {
      nuc-1-iso-image = nixos-generators.nixosGenerate {
        inherit pkgs;
        format = "install-iso";
        modules = [
          defaultModule
          ({
            config,
            lib,
            pkgs,
            ...
          }: let
            # disko
            disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.disko}'';
            disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
            disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";

            # system
            system = self.nixosConfigurations.nuc-1.config.system.build.toplevel;

            install-system = pkgs.writeShellScriptBin "install-system" ''
              set -euo pipefail

              echo "Formatting disks..."
              . ${disko-format}/bin/disko-format

              echo "Mounting disks..."
              . ${disko-mount}/bin/disko-mount

              echo "Installing system..."
              nixos-install --system ${system}

              echo "Done!"
            '';
          in {
            imports = [
              ../hosts/nuc-1/disko.nix
            ];

            # we don't want to generate filesystem entries on this image
            disko.enableConfig = lib.mkDefault false;

            # add disko commands to format and mount disks
            environment.systemPackages = [
              disko
              disko-mount
              disko-format
              install-system
            ];
          })
        ];
      };
    };
  };
}
```

And as I told you at the beginning of the article, I need to type `, flash-nuc-iso`, and you know the rest 😉!

## Summary

Once you start embracing the mantra: "everything is a derivation" your mindset will grow beyond your physical limits. It feels magical. Now I don't have to remember anything, and I don't need to write long READMEs with instructions. Instead, the code describes the whole system from installation to running it. How powerful is that?

Well, it turns out we can do even more fancy stuff! What if I told you we could take this concept further with [`nixos-remote`](https://github.com/numtide/nixos-remote)?

> nixos-remote makes it possible to install nixos from Linux machines reachable via ssh. Under the hood uses a kexec image to boot into a NixOS installer from a running Linux system. It then uses disko to partition and format the disks on the target system before it installs the user provided nixos configuration.

Go and have a look!

Also, I would like to thank [Brian](https://bmcgee.ie/), [Mic92](https://blog.thalheim.io/), [Zimbatm](https://zimbatm.com/), and others at [Numtide](https://numtide.com/). Without them, this article wouldn't be possible!

[Don't forget to look at my template](https://github.com/aldoborrero/templates/blob/main/templates/blog/nix/setting-up-machines-nix-style/), where you can see every file to solidify what I wrote above!

See you in my next article 👋🏻!
