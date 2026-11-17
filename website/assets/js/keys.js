// Keyboard shortcuts (_partials/keys-help.html lists them). Single keys, so
// they can be turned off in the "Aa" panel (WCAG 2.1.4): <html data-keys="off">.
// They never fire while typing in a field, with Ctrl/Alt/Meta held, or while
// a modal dialog (the image viewer, this help) owns the keyboard.

const root = document.documentElement;
const $ = (s) => document.querySelector(s);
const on = () => root.dataset.keys !== "off";
const visible = (el) => el && el.getClientRects().length > 0;
const typing = (el) =>
  el.isContentEditable ||
  /^(TEXTAREA|SELECT)$/.test(el.tagName) ||
  (el.tagName === "INPUT" && !/^(radio|checkbox|button|submit|reset|range|color|file)$/.test(el.type));

// Controls that have a shortcut say so (aria-keyshortcuts), only while on.
const labels = [
  [".search-link", "/"],
  [".aa", "a"],
  [".toc-button", "c"],
  [".pager a[rel=next]", "n"],
  [".pager a[rel=prev]", "p"],
  [".keys-hint", "?"],
];
const sync = () => {
  for (const [s, k] of labels) for (const el of document.querySelectorAll(s)) on() ? el.setAttribute("aria-keyshortcuts", k) : el.removeAttribute("aria-keyshortcuts");
};

let help;
const toggleHelp = () => {
  if (help?.open) return help.close();
  if (!help) {
    help = $("#keys-help").content.firstElementChild.cloneNode(true);
    document.body.append(help);
  }
  help.showModal();
};

// j / k: the entries of a list (home stream, sections, tags, search, series).
const step = (d) => {
  const links = [...document.querySelectorAll("main :is(.item, .entries > li, .til-list > li)")]
    .map((e) => e.querySelector(":is(h2, h3) a, a.permalink, a"))
    .filter(visible);
  if (!links.length) return;
  let i = links.indexOf(document.activeElement);
  if (i < 0) {
    // Nothing focused yet: start from what is on screen.
    i = links.findIndex((a) => a.getBoundingClientRect().top >= 0);
    i = i < 0 ? links.length : d > 0 ? i - 1 : i;
  }
  const a = links[Math.min(Math.max(i + d, 0), links.length - 1)];
  a.focus({ preventScroll: true });
  a.scrollIntoView({ block: "center", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
};

const contents = () => {
  const sheet = $("#toc-sheet");
  if (visible($(".toc-button")) && sheet?.showPopover) {
    sheet.showPopover();
    sheet.querySelector("a")?.focus();
  } else {
    $(".toc a")?.focus();
  }
};

const go = { h: "/", p: "/posts/", t: "/til/", a: "/about/" };
let g = 0;

const actions = {
  "/": () => {
    const q = $("#q");
    if (q) q.focus(), q.select();
    else location.href = "/search/";
  },
  "?": toggleHelp,
  a: () => {
    $(".aa:not([hidden])")?.click();
    if ($("#reading")?.matches(":popover-open")) $("#reading input:checked")?.focus();
  },
  t: () => $(`.reading input[name=theme]:not(:checked)`)?.click(),
  c: contents,
  j: () => step(1),
  k: () => step(-1),
  n: () => $(".pager a[rel=next]")?.click(),
  p: () => $(".pager a[rel=prev]")?.click(),
  g: () => (g = Date.now()),
};

addEventListener("keydown", (e) => {
  if (!on() || e.defaultPrevented || e.ctrlKey || e.altKey || e.metaKey || e.isComposing) return;
  if (typing(e.target)) return;
  const k = e.key;
  if ($("dialog[open]") && !(help?.open && k === "?")) return;
  if (g && Date.now() - g < 1500 && go[k]) {
    g = 0;
    e.preventDefault();
    location.href = go[k];
    return;
  }
  g = 0;
  const act = actions[k];
  // Shift is allowed: "?" needs it, and so does "/" on some layouts (Spanish);
  // Shift with a letter gives an uppercase key, which maps to nothing.
  if (!act) return;
  e.preventDefault();
  act();
});

// The footer hint opens the same help; it shows only with a fine pointer.
const hint = $(".keys-hint");
if (hint) {
  hint.addEventListener("click", toggleHelp);
  hint.hidden = !matchMedia("(hover: hover) and (pointer: fine)").matches;
}
document.addEventListener("change", (e) => e.target.name === "keys" && sync());
sync();
