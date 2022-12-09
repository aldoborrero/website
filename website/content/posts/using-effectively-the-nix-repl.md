---
title: Learn how to use the Nix REPL effectively
date: 2022-12-02
description: 'Improve your Nix knowledge with its REPL'
image: images/posts/using-effectively-the-nix-repl/cover.jpg
---

Inspecting Nix is hard! The dynamic nature of the language sometimes makes your head dizzy, especially when starting your first steps toward enlightenment in [NixOS](https://nixos.org). It is pretty common to suffer from the following issues:

- Has the infinite recursion error hit you? It happened to me.
- Has the Nix expression spitted a weird error with a bizarre stack trace resembling [Klingon](https://en.wikipedia.org/wiki/Klingon_language)? Yep, that too.
- Do you wonder what options/packages/nixos and home-manager modules the expression may produce? I have no idea.

Discoverability could be much better in the Nix/NixOS ecosystem despite having numerous resources/manuals/blog articles. To the uninitiated, it feels vast but, at the same time, shallow. Furthermore, it only makes sense **once** you have acquired some knowledge. So, trust me, you're not alone.

While I was writing the previous paragraph, it got me thinking next on the following fundamental question:

> How can discoverability be improved on Nix?

And suddenly remembered [this Vox's interview](https://youtu.be/K-NBcP0YUQI?t=151) with [Shigeru Miyamoto](https://en.wikipedia.org/wiki/Shigeru_Miyamoto) (creator of Super Mario Bros, Zelda, Donkey Kong, and other big Nintendo franchises). It turns out he has something to say about discoverability in video games:

<iframe width="560" height="315" src="https://www.youtube.com/embed/K-NBcP0YUQI" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

> When I design my games, I have to think about how I'm showing a situation to a player, conveying to them what they're supposed to do.
>
> In Mario, you keep moving to the right to reach the end goal. In Donkey Kong, you keep climbing up to rescue the captured princess.

The interview described Miyamoto's genius when he and his team worked on the first Super Mario Bros for the Nintendo Entertainment System (better known as Famicom or NES):

> A lot of Miyamoto's genius can be seen in the first level of Super Mario Bros. - probably the most iconic level in video game history. It's designed to naturally teach you the game mechanics while you play.
>
> If you look at a breakdown, there's a lot of really subtle design work going on here. Though Mario is usually at the centre of the screen, in this first scene he starts at the far left. All the empty space to the right of him gives you a sense of where to go.

![How the Inventor of Mario designs a Game](/images/posts/using-effectively-the-nix-repl/How_the_inventor_of_Mario_designs_a_game.gif)

I recommend seeing the whole interview as it's very insightful and entertaining (especially if you love video games, as I do!). But going back to Nix, I think those principles could be better enforced in the ecosystem.

I remember discussing with [Jonas Chevalier](https://twitter.com/zimbatm) in August the ideal path to learn Nix effectively, and during our interaction, I shared with him the following notes:

1. Learn the basics of the Nix language.
2. **Play around with the Nix REPL.**
3. Create your first flake, utils, and libs.
4. Use nix as a package manager first.
5. Learn how to solve your upstream Linux issues.
6. Move slowly towards NixOS.

There was a before and an after to understanding Nix in my particular case: the **REPL** (an acronym for [Read Eval Loop](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)). Unfortunately, the REPL is presented in the [NixOS Manual](https://nixos.org/manual/nixos/stable/#sec-modularity) in the Modularity section, a thing that, for the beginner, is too hidden to be understood as a valuable tool to use almost immediately. I know there are other places like [nix.wiki](https://nixos.wiki/wiki/Nix_command/repl), where there's a shy mention of the REPL and its benefits, but nothing more than a glorified summarized version of the [official docs for the command](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-repl.html).

How can you teach the basics without having a safe playground? It's also a thing [I was jokingly discussing on Mastodon](https://fosstodon.org/@aldo/109404422650458768):

![Difficulty of Nix](/images/posts/using-effectively-the-nix-repl/difficulty-of-nix.jpeg)

Nevertheless, what I presented above are my opinions on the subject. At this point of the article, you may wonder:

> Hey! Yeah, amazing divagations but: What can I do with the Nix REPL?

Let's start with the fun part!

## What can we do with the Nix REPL?

### The basics

Entering the REPL is relatively easy. Just write the following in your terminal:

```bash
$ nix repl
Welcome to Nix 2.11.1. Type :? for help.

nix-repl>
```

The REPL will greet you. There are shortcuts of commands available (some of them will be explored below) if you type `:?`:

```bash
$ nix repl
Welcome to Nix 2.11.1. Type :? for help.

nix-repl> :?
The following commands are available:

  <expr>        Evaluate and print expression
  <x> = <expr>  Bind expression to variable
  :a <expr>     Add attributes from resulting set to scope
  :b <expr>     Build a derivation
  :bl <expr>    Build a derivation, creating GC roots in the working directory
  :e <expr>     Open package or function in $EDITOR
  :i <expr>     Build derivation, then install result into current profile
  :l <path>     Load Nix expression and add it to scope
  :lf <ref>     Load Nix flake and add it to scope
  :p <expr>     Evaluate and print expression recursively
  :q            Exit nix-repl
  :r            Reload all files
  :sh <expr>    Build dependencies of derivation, then start nix-shell
  :t <expr>     Describe result of evaluation
  :u <expr>     Build derivation, then start nix-shell
  :doc <expr>   Show documentation of a builtin function
  :log <expr>   Show logs for a derivation
  :te [bool]    Enable, disable or toggle showing traces for errors
```

As you can see above, some of them are pretty explanatory. For example, to exit the REPL, we only need to write `:q`!

Also, remember that the REPL supports `<TAB>` completion, so don't hesitate to use it to autocomplete and save time!

Having explained the most basic command, let's move on to more exciting things!

### Load directly Nix expressions

You can quickly evaluate a random Nix expression:

```bash
$ nix repl --expr '{a = { b = 3; c = 4; }; }'
Welcome to Nix 2.11.0. Type :? for help.

Loading installable ''...
Added 1 variables.
nix-repl> a
{ b = 3; c = 4; }
```

The `--expr` flag is quite helpful to prime directly the Nix REPL with valuable data or values.

We can also add an `attrset` entirely to the scope of imported variables if we use `:add` or `:a` shortcut, which is the equivalent of the previous command inside the REPL:

```bash
$ nix repl
Welcome to Nix 2.11.0. Type :? for help.

nix-repl>:a {a = { b = 3; c = 4;}; d = "hello"; }
Added 1 variables.

nix-repl> a
{ b = 3; c = 4; }

nix-repl> d
"hello"
```

This is useful if you want to bring multiple variables simultaneously to the parent context.

**Note**: Do you remember the [JavaScript root scope](https://blog.bitsrc.io/understand-scope-in-javascript-e150f889ba72)? Nix behaves quite similarly!

### Load flakes

With previous knowledge, we can utilize the `--expr` flag to load a random [Nix Flake](https://nixos.wiki/wiki/Flakes) directly:

```bash
$ nix repl --expr 'builtins.getFlake "github:nix-community/ethereum.nix"'
Welcome to Nix 2.11.0. Type :? for help.

Loading installable ''...
Added 14 variables.
```

Also, you can load a flake directly inside the REPL with `:load-flake` or `:lf` shortcut:

```bash
$ nix repl
Welcome to Nix 2.11.0. Type :? for help.

nix-repl> :lf github:nix-community/home-manager
```

With this, you can quickly explore other Flakes and see their `inputs` and `outputs`!

**Question**: What happens if we try to load multiple Flakes? Do you remember the JavaScript root scope? 😉

**Note**: Are you aware that [Nix includes some useful `builtins` functions](https://nixos.org/manual/nix/stable/language/builtins.html) baked into the language? Feel free to explore those in the REPL!

### Load nixpkgs from <nixpkgs> shortcut

If we want, we can load our configured `<nixpkgs>` and import all of our packages:

```bash
$ nix repl --file '<nixpkgs>'
Welcome to Nix 2.11.0. Type :? for help.

Loading installable ''...
Added 17708 variables.
nix-repl>
```

We can, alternatively, load `<nixpkgs>` from inside the REPL, too with `:load` or `:l` shortcut:

```bash
$ nix repl
Welcome to Nix 2.11.0. Type :? for help.

nix-repl> :l <nixpkgs>
```

**Note**: Do you know how Nix knows where to load those `<nixpkgs>`?

```bash
$ echo $NIX_PATH
nixpkgs=/nix/store/j5a7i3dvxslg2ychfy53wdhg1m3xfrwm-source:home-manager=/nix/store/xg2ijnl5x1g64dv2hn23g39k6r5fn3sx-source

$ nix repl -f '<nixpkgs>'
Welcome to Nix 2.11.1. Type :? for help.

Loading installable ''...
Added 17714 variables.
nix-repl> :q

$ NIX_PATH=

$ nix repl -f '<nixpkgs>'
error: file 'nixpkgs' was not found in the Nix search path (add it using $NIX_PATH or -I)
```

The particular `$NIX_PATH` environment variable tells the Nix REPL to load the path specified in the expression `<nixpkgs>`! Furthermore, can we try to create our custom `<mynixpkgs>` and load that instead? Let's try it out!

```bash
$ git clone git@github.com:NixOS/nixpkgs.git
# Cloning...

$ NIX_PATH=mynixpkgs=/home/aldo/nixpkgs

$ echo $NIX_PATH
mynixpkgs=/home/aldo/nixpkgs

$ nix repl -f '<mynixpkgs>'
Welcome to Nix 2.11.1. Type :? for help.

Loading installable ''...
Added 17829 variables.
nix-repl>
```

It works!

**Pro-Tip**: What happens if you combine this with [`direnv`](https://direnv.net/) that allows you to load environment variables on the flight when entering certain directories? You can quickly load a Nix REPL with different versions of the `nixpkgs`! 🥳

### Load nixpkgs from tarballs

Another alternative approach is to load `nixpkgs` directly from a `gz` tarball (previous to Flakes, this was one the most used methods):

```bash
nix repl --expr 'import (builtins.fetchTarball https://github.com/NixOS/nixpkgs/archive/6bc6f77cb171a74001033d94f17f49043a9f1804.tar.gz) {system = "x86_64-linux";}'
Welcome to Nix 2.11.1. Type :? for help.

Loading installable ''...
Added 11958 variables.
nix-repl>
```

If you want to see the latest versions of the tarballs, you can navigate to [status.nixos.org](https://status.nixos.org) and see the different channels there. From there, it's just easy as copying the commit hash and importing it directly, as shown above.

**Note**: Also, notice how, in this particular case, I'm specifying arguments like `system = "x86_64-linux"` to customize how the `nixpkgs` are imported. You can also add other supported options like `config.allowUnfree = true`!

### Display build logs

We can quickly see the associated build logs for a package derivation with `:log:` shortcut (it will open your favorite pager, mine is `less`):

```bash
$ nix repl -f '<nixpkgs>'
Welcome to Nix 2.11.1. Type :? for help.

Loading installable ''...
Added 17714 variables.
nix-repl> :b pkgs.besu

This derivation produced the following outputs:
  out -> /nix/store/kf4xshk1lp16nbxcj9ar4lbf2dv7yqmv-besu-22.7.6

nix-repl> :log pkgs.besu
```

**Note**: Make sure to build first the package derivation, or the screen will be empty!

**Pro-Tip**: Do you recognize the different phases of building a package derivation inside the logs?

### Build package derivations

We can play around and build a derivation (a package) with `:b` shortcut for a given Flake:

```bash
$ nix repl --expr 'builtins.getFlake "github:nix-community/ethereum.nix"'
Welcome to Nix 2.11.0. Type :? for help.

Loading installable ''...
Added 14 variables.
nix-repl> :b outputs.packages.x86_64-linux.teku

This derivation produced the following outputs:
  out -> /nix/store/1k01brqgmr93y9f428s2kpkas79y9v4k-teku-22.12.0
```

The same can be repeated if we have loaded `<nixpkgs>` instead:

```bash
$ nix repl -f '<nixpkgs>'
Welcome to Nix 2.11.1. Type :? for help.

Loading installable ''...
Added 17714 variables.
nix-repl> :b pkgs.besu

This derivation produced the following outputs:
  out -> /nix/store/kf4xshk1lp16nbxcj9ar4lbf2dv7yqmv-besu-22.7.6
```

### Inspect code quickly

You can see the specific Nix expression of any expression or package derivation (it will open your default editor contained in the `$EDITOR` variable):

```bash
$ nix repl --expr 'builtins.getFlake "github:nix-community/ethereum.nix"'
Welcome to Nix 2.11.0. Type :? for help.

Loading installable ''...
Added 17708 variables.
nix-repl> :e packages.x86_64-linux.lighthouse
```

Bear in mind, though it will always open in read-only mode! But for reference and exploration, it's convenient!

**Question**: What do you think happens if we try to see the Nix implementation of a `builtin` function? Any guesses? 🤔

Aha! It turns out those `builtins` are directly C++ code! You can easily spot them by using `:t` shortcut!

```bash
nix-repl> :t builtins.getFlake
the built-in function 'getFlake'
```

**Challenge**: Fancy enough [to see the implementation of `builtins.getFlake`](https://github.com/NixOS/nix/blob/371013c08dc68d90c003ac677045ecbc9b463e8c/src/libexpr/flake/flake.cc#L193)? 😊

### Load a Nix shell with a package ready to be used

We can enter into a [`nix shell`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-shell.html) with `:u` shortcut so the specific package derivation will be compiled and ready for you to be used:

```bash
$ nix repl --expr 'builtins.getFlake "github:nix-community/ethereum.nix"'
Welcome to Nix 2.11.0. Type :? for help.

nix-repl> :u pkgs.besu
warning: error: plugin-files set after plugins were loaded, you may need to move the flag before the subcommand

[nix-shell:~]$ which besu
/nix/store/kf4xshk1lp16nbxcj9ar4lbf2dv7yqmv-besu-22.7.6/bin/besu

[nix-shell:~]$
```

This is the equivalent of doing something `nix shell nixpkgs#besu`! But with the convenience, you can always go back to your Nix REPL session!

### Search for specific documentation

We can access detailed documentation of a utility function:

```bash
nix-repl> :doc builtins.head
Synopsis: builtins.head list

    Return the first element of a list; abort evaluation if the argument isn’t a list or is
    an empty list. You can test whether a list is empty by comparing it with [].
```

Not every single function includes documentation, though! As [we can see from the Nix REPL implementation](https://github.com/NixOS/nix/blob/master/src/libcmd/repl.cc#L704).

### Know the type of expression or value

If you're wondering what's going to be the type of expression you can use `:t` shortcut:

```bash
nix-repl> :t 1 + 1
an integer
```

Which is almost the equivalent of using `builtins.typeOf`:

```bash
nix-repl> builtins.typeOf (1 + 1)
"int"
```

## How do I personally use the Nix REPL for development?

For example, when I'm developing on [ethereum.nix](https://github.com/nix-community/ethereum.nix) I tend to have my editor open and to the side an open REPL. With that alone, I can obtain an excellent feedback loop that keeps iterating as necessary until I have created a new package.

## What do I miss personally on the Nix REPL?

Before wrapping up this article, I would like to add my thoughts about new features or improvements we can make to the Nix REPL to improve our experience! Among those, we can talk about:

### Consistency in defining short and long commands

Whenever you type `:?` in the REPL, the help appears, indicating the available commands... But the extended version of the commands is missing! Type `:?` and search for `:load-flake`!

Yes, I know, it's highly improbable you'll tend to use the more extended version of a command, but sometimes it's helpful for teaching purposes, yet those are surprisingly not written!

### Improved syntax for loading flakes

I don't understand why loading flakes is not naturally baked into the `nix repl` command without using the `--expr` argument.

Right now, we can benefit from something like:

```bash
$ nix repl -f '<nixpkgs>'
```

And the same could be replicated with the following:

```bash
$ nix repl -fl 'github:nix-community/ethereum.nix'
```

Don't you agree it makes things more convenient? The good thing is preparing a PR with this proposal is quite straightforward!

Do you want to tackle it by creating a PR?

### Improved history

It's very convenient having a REPL that allows using your arrow keys to navigate backward and forward in the command history!

But what if I told you about creating a new command called `:history` or `:h` that displays the list of entered commands like [`history` does in Linux](https://opensource.com/article/18/6/history-command)?

Fancy creating a PR too?

### Open the file explorer

Sometimes when you're building a package derivation, you would like to explore its contents. What if a direct command would open your file explorer directly? I use the awesome [`lf`](https://github.com/gokcehan/lf) and [`thunar`](https://docs.xfce.org/xfce/thunar/start), and I think it will save me some typing if this was integrated internally.

### Clean the REPL environment

Surprisingly the Nix REPL offers the `:r` (reload) command, but there's no `:clean` or `:cc` (`:c` is reserved for the `:debuger` command) to clean the environment!

Sometimes I pollute the environment so much that, ideally, I would like to reset things to a pristine state without having to type `:q` and later write `nix repl` again.

It turns out that adding this feature is very simple, just modifying the source code of `src/libcmd/repl.cc`.

```c
# More lines of code...

else if (command == ":lf" || command == ":load-flake") {
  loadFlake(arg);
}

else if (command == ":r" || command == ":reload") {
  state->resetFileCache();
  reloadFiles();
}

else if (command == ":cc" || command == ":clear") {
  state->resetFileCache();
  initEnv();
}

# More lines of code
```

A [PR has been created with this change already](https://github.com/NixOS/nix/pull/7439)!

## What about you?

Can you showcase more cool tricks you know about the Nix REPL that I haven't mentioned here?

See you in the following article 👋!
