// Image viewer. Progressive enhancement over the links the image render hook
// writes (<a class="zoom" data-zoom href="full.jpg"><img></a>): without this
// script they open the file; with it they open a modal <dialog> with zoom
// (click, wheel, pinch, keys), pan (drag) and previous/next within the entry.

const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)");
const icon = (d) =>
  `<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true" focusable="false"><path d="${d}" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
const LENS = "M10.5 4a6.5 6.5 0 1 0 0 13 6.5 6.5 0 0 0 0-13zM15.3 15.3 20 20";
const ZOOM_IN = `${LENS}M10.5 7.5v6M7.5 10.5h6`;
const ZOOM_OUT = `${LENS}M7.5 10.5h6`;

let dlg, stage, img, cap, count, btnZoom, btnClose, btnPrev, btnNext;
let items = [];
let idx = 0;
let trigger = null;
// Stage size, image size in image pixels, scale, translation (screen px).
let W = 0, H = 0, iw = 1, ih = 1, k = 1, kFit = 1, x = 0, y = 0;
// Space kept clear around the fitted image for the controls and caption.
let padX = 0, padTop = 0, padBottom = 0;

const pointers = new Map();
let gesture = null;
let moved = false;

function build() {
  dlg = document.createElement("dialog");
  dlg.className = "zv";
  dlg.setAttribute("aria-modal", "true");
  dlg.setAttribute("aria-label", "Image viewer");
  dlg.innerHTML =
    `<div class="zv-stage"><img class="zv-img" alt="" draggable="false"></div>` +
    `<p class="zv-count" aria-live="polite"></p>` +
    `<div class="zv-tools">` +
    `<button type="button" class="zv-btn zv-zoom" aria-pressed="false" aria-label="Zoom in">${icon(ZOOM_IN)}</button>` +
    `<button type="button" class="zv-btn zv-close" aria-label="Close">${icon("M6 6l12 12M18 6 6 18")}</button>` +
    `</div>` +
    `<button type="button" class="zv-btn zv-prev" aria-label="Previous image">${icon("M15 5l-7 7 7 7")}</button>` +
    `<button type="button" class="zv-btn zv-next" aria-label="Next image">${icon("M9 5l7 7-7 7")}</button>` +
    `<p class="zv-cap"></p>`;
  const $ = (s) => dlg.querySelector(s);
  stage = $(".zv-stage");
  img = $(".zv-img");
  cap = $(".zv-cap");
  count = $(".zv-count");
  btnZoom = $(".zv-zoom");
  btnClose = $(".zv-close");
  btnPrev = $(".zv-prev");
  btnNext = $(".zv-next");
  document.body.append(dlg);

  btnClose.addEventListener("click", () => dlg.close());
  btnPrev.addEventListener("click", () => show(idx - 1));
  btnNext.addEventListener("click", () => show(idx + 1));
  btnZoom.addEventListener("click", () => toggleZoom(W / 2, H / 2));

  // Backdrop and empty stage close; the image itself toggles zoom. Pointer
  // capture retargets clicks to the stage, so hit-test the image by position.
  dlg.addEventListener("click", (e) => {
    if (moved || (e.target !== dlg && e.target !== stage && e.target !== img)) return;
    const r = img.getBoundingClientRect();
    const onImg = e.clientX >= r.left && e.clientX <= r.right && e.clientY >= r.top && e.clientY <= r.bottom;
    if (onImg) toggleZoom(e.clientX, e.clientY);
    else dlg.close();
  });

  dlg.addEventListener("keydown", onKey);
  dlg.addEventListener("close", onClose);
  stage.addEventListener("wheel", onWheel, { passive: false });
  stage.addEventListener("pointerdown", onDown);
  stage.addEventListener("pointermove", onMove);
  stage.addEventListener("pointerup", onUp);
  stage.addEventListener("pointercancel", onUp);
  addEventListener("resize", () => dlg.open && measure(true));
  // Back gesture or button closes the viewer instead of leaving the page.
  addEventListener("popstate", () => dlg.open && dlg.close());
}

function open(a) {
  if (!dlg) build();
  trigger = a;
  items = [...(a.closest("article") || document).querySelectorAll("a[data-zoom]")];
  dlg.showModal();
  show(items.indexOf(a));
  history.pushState({ zoomViewer: true }, "");
  btnClose.focus();
}

function onClose() {
  pointers.clear();
  gesture = null;
  if (history.state && history.state.zoomViewer) history.back();
  if (trigger) trigger.focus({ preventScroll: true });
}

function show(i) {
  idx = (i + items.length) % items.length;
  const a = items[idx];
  const thumb = a.querySelector("img");
  iw = +thumb.getAttribute("width") || thumb.naturalWidth || 1;
  ih = +thumb.getAttribute("height") || thumb.naturalHeight || 1;
  img.alt = thumb.alt;
  // Show what the page already has, then swap in the full-size file.
  const full = a.href;
  img.src = thumb.currentSrc || full;
  if (img.src !== full) {
    const pre = new Image();
    pre.onload = () => {
      if (items[idx] !== a) return;
      img.src = full;
      if (!thumb.getAttribute("width")) {
        iw = pre.naturalWidth;
        ih = pre.naturalHeight;
        measure(false);
      }
    };
    pre.src = full;
  }
  const fig = a.closest("figure");
  const caption = fig && fig.querySelector("figcaption");
  cap.textContent = caption ? caption.textContent.trim() : "";
  cap.hidden = !cap.textContent;
  const many = items.length > 1;
  btnPrev.hidden = btnNext.hidden = !many;
  count.textContent = many ? `${idx + 1} / ${items.length}` : "";
  measure(false);
}

function measure(keep) {
  const r = stage.getBoundingClientRect();
  const wasFit = k <= kFit * 1.001;
  W = r.width;
  H = r.height;
  const narrow = W < 640;
  padX = narrow || btnPrev.hidden ? 8 : 64;
  padTop = 64;
  padBottom = cap.hidden ? 16 : cap.offsetHeight + 16;
  kFit = Math.min((W - 2 * padX) / iw, (H - padTop - padBottom) / ih, 1);
  img.style.width = `${iw}px`;
  img.style.height = `${ih}px`;
  if (keep && !wasFit) clamp(), apply();
  else reset();
}

const kMax = () => Math.max(2, kFit * 8);

function reset() {
  k = kFit;
  clamp();
  apply();
}

function zoomTo(nk, cx, cy) {
  nk = Math.min(kMax(), Math.max(kFit, nk));
  x = cx - ((cx - x) * nk) / k;
  y = cy - ((cy - y) * nk) / k;
  k = nk;
  clamp();
  apply();
}

function toggleZoom(cx, cy) {
  animate();
  if (k > kFit * 1.01) reset();
  // 1:1 when that is a real step up, otherwise twice the fitted size.
  else zoomTo(kFit < 0.75 ? 1 : kFit * 2, cx, cy);
}

// Centre an axis that fits; keep the edges on screen for one that doesn't.
function axis(pos, size, view, before, after) {
  if (size <= view - before - after) return before + (view - before - after - size) / 2;
  if (size <= view) return (view - size) / 2;
  return Math.min(0, Math.max(view - size, pos));
}

function clamp() {
  x = axis(x, iw * k, W, padX, padX);
  y = axis(y, ih * k, H, padTop, padBottom);
}

function apply() {
  img.style.transform = `translate(${x}px, ${y}px) scale(${k})`;
  const zoomed = k > kFit * 1.01;
  dlg.classList.toggle("is-zoomed", zoomed);
  btnZoom.setAttribute("aria-pressed", String(zoomed));
  btnZoom.setAttribute("aria-label", zoomed ? "Zoom out" : "Zoom in");
  btnZoom.innerHTML = icon(zoomed ? ZOOM_OUT : ZOOM_IN);
}

function animate() {
  if (reduceMotion.matches) return;
  img.classList.add("zv-anim");
  setTimeout(() => img.classList.remove("zv-anim"), 220);
}

function onKey(e) {
  const key = e.key;
  if (key === "ArrowRight" && items.length > 1) show(idx + 1);
  else if (key === "ArrowLeft" && items.length > 1) show(idx - 1);
  else if (key === "+" || key === "=") animate(), zoomTo(k * 1.5, W / 2, H / 2);
  else if (key === "-") animate(), zoomTo(k / 1.5, W / 2, H / 2);
  else if (key === "0") animate(), reset();
  else if (key === "Tab") return trap(e);
  else return;
  e.preventDefault();
}

// The modal dialog already makes the page inert; this keeps Tab cycling
// through the viewer's own controls instead of escaping to the browser UI.
function trap(e) {
  const f = [...dlg.querySelectorAll("button")].filter((b) => !b.hidden);
  const first = f[0];
  const last = f[f.length - 1];
  if (e.shiftKey && document.activeElement === first) last.focus(), e.preventDefault();
  else if (!e.shiftKey && document.activeElement === last) first.focus(), e.preventDefault();
}

function onWheel(e) {
  e.preventDefault();
  const unit = e.deltaMode === 1 ? 16 : 1;
  // Trackpad pinch arrives as wheel + ctrlKey, with small deltas.
  const rate = e.ctrlKey ? 0.01 : 0.002;
  zoomTo(k * Math.exp(-e.deltaY * unit * rate), e.clientX, e.clientY);
}

function onDown(e) {
  if (e.button !== 0) return;
  stage.setPointerCapture(e.pointerId);
  pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
  moved = false;
  begin();
}

function begin() {
  const p = [...pointers.values()];
  if (p.length === 1) {
    const zoomed = k > kFit * 1.01;
    gesture = { type: zoomed ? "pan" : "swipe", sx: p[0].x, sy: p[0].y, x0: x, y0: y };
  } else if (p.length === 2) {
    const mx = (p[0].x + p[1].x) / 2;
    const my = (p[0].y + p[1].y) / 2;
    gesture = { type: "pinch", d0: dist(p), k0: k, mx, my, x0: x, y0: y };
  }
}

const dist = (p) => Math.hypot(p[0].x - p[1].x, p[0].y - p[1].y) || 1;

function onMove(e) {
  if (!pointers.has(e.pointerId) || !gesture) return;
  pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
  const p = [...pointers.values()];
  if (gesture.type === "pinch" && p.length === 2) {
    const mx = (p[0].x + p[1].x) / 2;
    const my = (p[0].y + p[1].y) / 2;
    const nk = Math.min(kMax(), Math.max(kFit * 0.8, (gesture.k0 * dist(p)) / gesture.d0));
    x = mx - ((gesture.mx - gesture.x0) * nk) / gesture.k0;
    y = my - ((gesture.my - gesture.y0) * nk) / gesture.k0;
    k = nk;
    moved = true;
    apply();
    return;
  }
  const dx = e.clientX - gesture.sx;
  const dy = e.clientY - gesture.sy;
  if (Math.abs(dx) + Math.abs(dy) > 6) moved = true;
  if (gesture.type === "pan") {
    x = gesture.x0 + dx;
    y = gesture.y0 + dy;
    clamp();
    apply();
  } else if (gesture.type === "swipe" && items.length > 1) {
    // Follow the finger sideways as feedback; decided on release.
    x = gesture.x0 + dx;
    apply();
  }
}

function onUp(e) {
  if (!pointers.delete(e.pointerId)) return;
  const g = gesture;
  gesture = null;
  if (g && g.type === "swipe") {
    const dx = e.clientX - g.sx;
    const dy = e.clientY - g.sy;
    if (items.length > 1 && Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy)) show(idx + (dx < 0 ? 1 : -1));
    else animate(), reset();
  } else if (g && g.type === "pinch") {
    if (k < kFit) animate(), reset();
    else clamp(), apply();
  }
  // Lifting one finger of a pinch continues as a pan with the other.
  if (pointers.size) begin();
}

document.addEventListener("click", (e) => {
  const a = e.target.closest && e.target.closest("a[data-zoom]");
  if (!a || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
  e.preventDefault();
  open(a);
});
