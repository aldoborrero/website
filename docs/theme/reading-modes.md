# Dark themes against browser reading modes

Benchmark for GOAL-15 (eye strain in the dark palettes), 18 November 2026. Contrast is WCAG 2.x, computed from the hex values. "Verified" means read from the product's source at the revision below. "Unverified" means not published anywhere reliable; no value is guessed.

## Reading modes

| | Firefox Reader View | Chrome Reading mode | Edge Immersive Reader | Safari Reader | Apple Books night | Kindle dark |
| --- | --- | --- | --- | --- | --- | --- |
| Dark background | `#1c1b22` | `#202124` (Google Grey 900) | unverified | unverified | unverified | black (inverted page) |
| Dark text | `#fbfbfe` | `#e3e3e3` | unverified | unverified | unverified | white (inverted) |
| Dark links | `#00ddff` (visited `#e675fd`) | `#8ab4f8` (Google Blue 300) | unverified | unverified | unverified | unverified |
| Text : background | **16.5 : 1** | **12.5 : 1** | — | — | — | unverified |
| Link : background | 10.4 : 1 | 7.6 : 1 | — | — | — | — |
| Light text : background | 18.3 : 1 (`#15141a` on `#fff`) | 16.5 : 1 (`#1f1f1f` on `#fff`) | — | — | — | — |
| Default font | `sans-serif` | Poppins (English) | unverified | unverified | unverified | unverified |
| Default size | 20 px (level 5: `10 + 2 × 5`) | font scale 2 × the 13 px panel base ≈ 26 px (derived) | unverified | unverified | unverified | unverified |
| Line height | 1.6 (level 4: `1 + 0.2 × 3`) = 32 px | 1.5 ("loose", the default) | unverified | unverified | unverified | unverified |
| Measure | `max-width: 30em` = 600 px at 20 px; 64 characters per line measured on the Jellyfin article | `max-width: 60ch`, inside a side panel that is usually narrower | unverified | unverified | unverified | unverified |

Notes:

- **Firefox:** follows the system light/dark preference by default (`reader.color_scheme = "auto"`). Its dark theme also dims images with `brightness(0.8) contrast(1.2)`. A separate Contrast theme is white on black (21:1).
- **Chrome:** besides dark, it has a low-contrast dark theme: `#9b958d` on `#302b26`, 4.7:1. The default theme follows Chrome's own Material theme, so its exact values vary.
- **Edge:** Microsoft documents the controls (text size, spacing, page themes, 23 of them in one document, some modelled on Irlen spectral filters) but no values.
- **Safari and Apple Books:** Apple publishes no Reader CSS or theme colours. The Books guide documents only the theme names, Bold Text and a background setting.
- **Kindle:** Amazon documents dark mode as an inversion of page and text, and "Page Color: black" on Colorsoft. No hex values are published.

## This site, dark mode, before and after

Body text is Newsreader at 20 px, line height 33 px (1.65), in a 608 px column, measured on the Jellyfin article at 1440 px:

- Light: weight 400, 70 characters per line.
- Dark, after: weight 440, 65 characters per line.

| Palette | Background | Body ink | Ink : bg | Headings : bg | Muted : bg / on mark | Accent : bg / on mark | Code kw / str on code bg | Warn : bg |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Medianoche, before | `#121a26` | `#dfe6f0` | 13.9 | 13.9 | 6.6 / 5.6 | 8.7 / 7.4 | 11.0 / 11.4 | 8.5 |
| Medianoche, after | `#18202c` | `#d7dee6` | **12.1** | 14.0 | 6.8 / 5.7 | 7.5 / 6.3 | 9.5 / 9.6 | 8.5 |
| Ámbar, before | `#1a1713` | `#ece4d6` | 14.1 | 14.1 | 6.9 / 6.0 | 9.8 / 8.5 | 10.5 / 11.5 | 8.7 |
| Ámbar, after | `#201d19` | `#e1dacd` | **12.1** | 14.0 | 7.1 / 6.0 | 7.5 / 6.4 | 9.6 / 9.5 | 8.7 |
| Índigo y oro, before | `#161a33` | `#e6e8f5` | 14.0 | 14.0 | 7.3 / 6.0 | 10.1 / 8.2 | 10.8 / 11.0 | 8.3 |
| Índigo y oro, after | `#1c203a` | `#dddfea` | **12.0** | 14.0 | 7.5 / 6.1 | 7.5 / 6.0 | 9.5 / 9.6 | 8.3 |
| Ciruela, before | `#1a1520` | `#ebe4ef` | 14.4 | 14.4 | 7.0 / 6.0 | 9.2 / 7.9 | 11.1 / 11.8 | 8.7 |
| Ciruela, after | `#201b26` | `#ded8e1` | **12.0** | 14.0 | 7.2 / 6.1 | 7.5 / 6.4 | 9.5 / 9.5 | 8.7 |
| Grafito y cobalto, before | `#16181c` | `#e4e6ea` | 14.2 | 14.2 | 6.8 / 5.8 | 7.2 / 6.2 | 9.6 / 11.4 | 8.6 |
| Grafito y cobalto, after | `#1c1e22` | `#d9dbde` | **12.0** | 14.0 | 7.0 / 5.9 | 7.5 / 6.4 | 9.5 / 9.5 | 8.6 |

Every pair listed in AGENTS.md passes AA (4.5:1) in every dark palette after the change. The lowest is muted on `--mark`, at 5.7:1.

Light mode is unchanged. Body ink is 15.0–16.7:1 on the background across the five palettes, close to Chrome's light theme (16.5) and below Firefox's (18.3). Muted is 5.9–6.5:1 and accent 5.9–7.6:1.

## What the benchmark decided

- **Body ink, 12:1 (not the 10–11:1 the goal first suggested).** Chrome's dark reading theme, the calmer of the two that publish values, sits at 12.5:1, and Firefox at 16.5:1. Nothing documented goes as low as 10–11:1 except Chrome's explicit low-contrast theme (4.7:1). Our old 14:1 was between the two. 12:1 follows Chrome's choice: a light grey (`#e3e3e3`), not near-white, on a ground lifted off black (`#202124`).
  - **Trade-off:** going lower would cut halation further, but would fall below every reading-mode default. At 20 px, grey text at 10:1 reads as washed out on the Windows panels Aldo uses. If 12:1 still tires his eyes, the next step is 11:1 for body text only.
- **Lifted grounds.** Both readers use a lifted dark grey rather than near-black: Firefox `#1c1b22` (relative luminance 0.011), Chrome `#202124` (0.015). Ours moved from 0.008–0.011 to 0.011–0.014, keeping each palette's hue.
- **Headings at 14:1** (a new `--head` token; in light mode it equals `--ink`). Headings stay as bright as before, so the hierarchy holds while body text calms down.
- **Weight 440 in dark.** Neither reader changes weight in dark mode, but both use a sans face, whose strokes are uniform. Newsreader's hairlines are much thinner, and light-on-dark rendering on Windows thins them further. A small step on the variable `wght` axis (the self-hosted woff2 files keep `wght` 200–800 and `opsz` 6–72) restores stroke density without looking bold. The cost is about 7% fewer characters per line (70 → 65), still inside the 60–70 range both readers target.
- **Size, line height and measure stay.** 20 px / 1.65 and about 65 characters per line match Firefox's defaults (20 px / 1.6 / about 64 characters per line) and sit inside Chrome's 60ch cap.
- **Accent, 7.5:1 and about 18% less chroma.** That is Chrome's link contrast (7.6), not Firefox's saturated cyan (10.4). Underlines in prose are a mix of accent and ground and turn full accent on hover and focus. They never disappear, so links don't rely on colour alone.
- **Smoothing.** Neither reader sets `-webkit-font-smoothing`. Dark mode now uses `auto` (greyscale `antialiased` thins light text on macOS); light keeps `antialiased`.

## Sources

Firefox, `mozilla-firefox/firefox` at `e1bdb5893e652b10528c1e5422d3c90ff146b2da`:

- **Theme colours**, `toolkit/themes/shared/aboutReader.css`:
  - dark and light, lines 10–13;
  - sepia, lines 80–81;
  - link colours, lines 30, 62, 65, 106 and 119;
  - the image filter, lines 111–113;
  - `max-width`, lines 963–967.
- **Size, line height and width formulas**, `toolkit/components/reader/AboutReader.sys.mjs`, lines 37–41, 725, 858 and 869.
- **Defaults**, `modules/libpref/init/all.js`:
  - `reader.font_size` 5, line 3487;
  - `reader.font_type` `sans-serif`, line 3490;
  - `reader.content_width` 3, line 3502;
  - `reader.line_height` 4, line 3505;
  - `reader.color_scheme` `auto`, line 3519.
- **Measured rendering:** Playwright Firefox 157, `about:reader` on the Jellyfin article (contact sheet).

Chromium, `chromium/src` at `cfa38501d445c4a5fdbb2d0941f8667fcdadb4e9`:

- **Colours:**
  - `chrome/browser/ui/color/chrome_color_mixer.cc`: background lines 873–876, text 905–908, links 1125–1128, low contrast 877–881 and 909–914;
  - `ui/gfx/color_palette.h`: the Google colour hex values.
- **Font:** `chrome/common/read_anything/read_anything_util.cc`, Poppins first, lines 84–88.
- **Settings:**
  - `chrome/browser/ui/read_anything/read_anything_prefs.cc`: font scale and font;
  - `chrome/common/read_anything/read_anything.mojom`: line spacing, `kLoose` the default, lines 137–142;
  - `chrome/renderer/accessibility/read_anything/read_anything_app_controller.cc`: spacing values, lines 2571–2597.
- **Width:**
  - `chrome/renderer/accessibility/read_anything/read_anything_node_utils.h`: `kMaxLineWidth = 60`;
  - `chrome/browser/resources/side_panel/read_anything/app/app_style_updater.ts`, line 90, and `app.css`, line 209: `max-width: <n>ch`.
- **Base size:** `ui/webui/resources/css/text_defaults_md.css`, line 41: a body size of 81.25%.

Other products:

- **Edge:**
  - <https://support.microsoft.com/en-us/topic/use-immersive-reader-in-microsoft-edge-72ac6331-2795-42eb-b3e8-c03503231f32>
  - <https://support.microsoft.com/en-us/microsoft-edge/accessibility-features-in-microsoft-edge-4c696192-338e-9465-b2cd-bd9b698ad19a>
- **Apple Books:** <https://support.apple.com/guide/books/change-a-books-appearance-ibks8923126d/mac>
- **Kindle:**
  - <https://www.amazon.com/gp/help/customer/display.html?nodeId=TZRTRCyYYbxMsMHDu8>
  - <https://www.amazon.com/gp/help/customer/display.html?nodeId=TABlJ4ot69emTO8jJG>
