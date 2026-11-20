// Mastodon replies (_partials/replies.html). The button appears only with JS;
// one click fetches the toot's public context from its own server and lists
// the replies. Their HTML is rebuilt node by node from an allow-list (no
// innerHTML of anything that came from the server).

const box = document.querySelector(".replies");
const button = box.querySelector(".replies-load");
const status = box.querySelector(".replies-status");
const list = box.querySelector(".reply-list");
const lang = box.closest("[lang]")?.lang || "en";

const KEEP = new Set(["P", "BR", "A", "SPAN", "STRONG", "B", "EM", "I", "CODE", "PRE", "BLOCKQUOTE", "UL", "OL", "LI", "DEL", "S"]);
const DROP = new Set(["SCRIPT", "STYLE", "IFRAME", "OBJECT", "EMBED", "TEMPLATE", "SVG", "MATH", "FORM", "INPUT", "BUTTON", "TEXTAREA", "SELECT", "IMG", "VIDEO", "AUDIO", "LINK", "META"]);

const safeUrl = (href) => {
  try {
    const u = new URL(href);
    return u.protocol === "https:" || u.protocol === "http:" ? u.href : null;
  } catch {
    return null;
  }
};

// Copies the allowed parts of `from` into `to`. Elements outside the
// allow-list keep their text (their children are copied in their place);
// dangerous ones are dropped with their content. Mastodon's link shortening
// is kept: "invisible" spans are skipped, "ellipsis" ones get an ellipsis.
const copy = (from, to) => {
  for (const node of from.childNodes) {
    if (node.nodeType === Node.TEXT_NODE) {
      to.append(node.data);
      continue;
    }
    if (node.nodeType !== Node.ELEMENT_NODE || DROP.has(node.tagName)) continue;
    if (node.classList.contains("invisible")) continue;
    if (!KEEP.has(node.tagName)) {
      copy(node, to);
      continue;
    }
    // A link whose address isn't http(s) stays as its text.
    const href = node.tagName === "A" ? safeUrl(node.getAttribute("href") || "") : null;
    const el = document.createElement(node.tagName === "A" && !href ? "SPAN" : node.tagName);
    if (href) {
      el.href = href;
      el.rel = "nofollow ugc noopener";
    }
    copy(node, el);
    if (node.classList.contains("ellipsis")) el.append("…");
    to.append(el);
  }
};

const sanitise = (html) => {
  const out = document.createDocumentFragment();
  copy(new DOMParser().parseFromString(html, "text/html").body, out);
  return out;
};

// "17 November 2026", as on the rest of the site.
const when = new Intl.DateTimeFormat(lang === "en" ? "en-GB" : lang, { day: "numeric", month: "long", year: "numeric" });

const reply = (s, depth) => {
  const li = document.createElement("li");
  li.className = "reply";
  if (depth > 0) li.dataset.depth = Math.min(depth, 3);
  const a = s.account || {};
  const head = document.createElement("p");
  head.className = "reply-head";
  const avatar = safeUrl(a.avatar_static || a.avatar || "");
  const img = document.createElement(avatar ? "img" : "span");
  img.className = "reply-avatar";
  if (avatar) {
    img.src = avatar;
    img.alt = "";
    img.width = img.height = 40;
    img.loading = "lazy";
    img.referrerPolicy = "no-referrer";
  }
  head.append(img);
  const who = document.createElement("a");
  who.className = "reply-author";
  who.href = safeUrl(a.url || "") || "#";
  who.rel = "nofollow ugc noopener";
  const name = document.createElement("strong");
  name.textContent = a.display_name || a.username || "";
  const handle = document.createElement("span");
  handle.textContent = "@" + (a.acct || a.username || "");
  who.append(name, handle);
  const date = document.createElement("a");
  date.className = "reply-date";
  date.href = safeUrl(s.url || s.uri || "") || "#";
  date.rel = "nofollow ugc noopener";
  const time = document.createElement("time");
  time.dateTime = s.created_at;
  time.textContent = when.format(new Date(s.created_at));
  date.append(time);
  head.append(who, date);

  const body = document.createElement("div");
  body.className = "reply-body";
  if (s.language) body.lang = s.language;
  if (s.spoiler_text) {
    const details = document.createElement("details");
    const summary = document.createElement("summary");
    summary.textContent = s.spoiler_text;
    details.append(summary, sanitise(s.content || ""));
    body.append(details);
  } else {
    body.append(sanitise(s.content || ""));
  }
  li.append(head, body);
  return li;
};

button.addEventListener("click", async () => {
  button.disabled = true;
  status.textContent = box.dataset.loading;
  try {
    const res = await fetch(box.dataset.context, { headers: { Accept: "application/json" }, referrerPolicy: "no-referrer" });
    if (!res.ok) throw new Error(res.status);
    const { descendants = [] } = await res.json();
    const depth = { [box.dataset.toot]: -1 };
    const items = [];
    for (const s of descendants) {
      if (s.visibility && s.visibility !== "public" && s.visibility !== "unlisted") continue;
      depth[s.id] = (depth[s.in_reply_to_id] ?? -1) + 1;
      items.push(reply(s, depth[s.id]));
    }
    list.replaceChildren(...items);
    const n = items.length;
    status.textContent = n === 0 ? box.dataset.none : n === 1 ? box.dataset.one : box.dataset.many.replace("%d", n);
    button.hidden = true;
  } catch {
    status.textContent = box.dataset.error;
    button.disabled = false;
  }
});

button.hidden = false;
box.querySelector(".replies-note").hidden = false;
