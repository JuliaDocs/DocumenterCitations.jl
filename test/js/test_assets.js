/* Tests for the bundled browser assets, run by `test/test_js_assets.jl`.
 *
 * Run directly with
 *
 *     node test/js/test_assets.js
 *
 * The scripts are evaluated against the fake DOM in `dom.js`. These tests
 * cover the decisions the scripts make about which link the reader followed;
 * the appearance of the popups and of the marked backlink is not testable
 * here, and was checked in a browser.
 */
"use strict";

const assert = require("assert");
const { element, page, load } = require("./dom.js");

const CLASS = "is-current-citation";
const STORAGE_KEY = "documentercitations-followed-citation";

const tests = [];
function test(name, fn) {
  tests.push([name, fn]);
}

// A bibliography page with one entry that is cited twice. As in the rendered
// HTML, the backlinks sit in a `span` inside the `div` carrying the anchor of
// the entry, and point to the citations on another page.
function bibliographyPage(options) {
  options = options || {};
  const backlinks = [
    element("a", { href: "../index.html#GoerzQ2022-cite-1" }),
    element("a", { href: "../index.html#GoerzQ2022-cite-2" }),
  ];
  const entry = element("div", {
    id: "GoerzQ2022",
    children: [element("span", { children: backlinks })],
  });
  const p = page({ hash: options.hash, backlinks: backlinks });
  if (options.followed) p.storage[STORAGE_KEY] = options.followed;
  return Object.assign(p, { backlinks: backlinks, entry: entry });
}

function marked(p) {
  return p.backlinks.map((a) => a.classList.contains(CLASS));
}


test("the backlink for the followed citation is marked", () => {
  // The reader clicked the second citation, which led to the entry
  const p = bibliographyPage({ followed: "GoerzQ2022-cite-2", hash: "#GoerzQ2022" });
  load("citations-backlinks.js", p);
  assert.deepStrictEqual(marked(p), [false, true]);
});


test("no backlink is marked when the bibliography is opened from the sidebar", () => {
  // Same session, but this time the reader did not arrive at the entry: the
  // citation followed earlier must not leave a mark (Documenter has no page
  // load between pages, so the id is still in `sessionStorage`)
  const p = bibliographyPage({ followed: "GoerzQ2022-cite-2", hash: "" });
  load("citations-backlinks.js", p);
  assert.deepStrictEqual(marked(p), [false, false]);
});


test("no backlink is marked when arriving at a section of the bibliography", () => {
  const p = bibliographyPage({
    followed: "GoerzQ2022-cite-2",
    hash: "#Cited-References",
  });
  load("citations-backlinks.js", p);
  assert.deepStrictEqual(marked(p), [false, false]);
});


test("the mark survives a click on one of Documenter's own controls", () => {
  // The settings button and the sidebar toggle are `<a>` elements with an
  // `id`, but they are not citations: clicking one must neither be remembered
  // nor unmark the backlink of the citation the reader actually followed
  const p = bibliographyPage({ followed: "GoerzQ2022-cite-1", hash: "#GoerzQ2022" });
  load("citations-backlinks.js", p);
  assert.deepStrictEqual(marked(p), [true, false]);
  const gear = element("a", { id: "documenter-settings-button", href: "#" });
  p.document.fire("click", { target: gear });
  assert.strictEqual(p.storage[STORAGE_KEY], "GoerzQ2022-cite-1");
  assert.deepStrictEqual(marked(p), [true, false]);
});


test("clicking a citation is remembered", () => {
  const p = bibliographyPage({ hash: "" });
  load("citations-backlinks.js", p);
  const citation = element("a", {
    id: "GoerzQ2022-cite-2",
    href: "references/index.html#GoerzQ2022",
  });
  // The click is on the text inside the link, as it would be in a browser
  p.document.fire("click", { target: element("em", { children: [] }) });
  assert.strictEqual(p.storage[STORAGE_KEY], undefined);
  p.document.fire("click", { target: citation });
  assert.strictEqual(p.storage[STORAGE_KEY], "GoerzQ2022-cite-2");
  // With the bibliography on the same page, there is no load to pick it up
  assert.deepStrictEqual(marked(p), [false, true]);
});


// A page with a citation link, for the hover popups. Both the data and the
// link point at the bibliography page, which is what gives the link a popup.
function citationPage(hash) {
  const link = element("a", {
    id: "GoerzQ2022-cite-1",
    href: "https://example.org/docs/references/index.html#GoerzQ2022",
  });
  const p = page({
    hash: hash || "",
    links: [link],
    scriptSrc:
      "https://example.org/docs/assets/documentercitations/citations-hover.js",
    hoverData: {
      GoerzQ2022: { html: "<p>M. H. Goerz et al.</p>", page: "references/index.html" },
    },
  });
  load("citations-hover.js", p);
  return Object.assign(p, { link: link });
}

function popupShown(p) {
  return p.link.getAttribute("aria-describedby") !== null;
}

// Following a backlink to a citation focuses it. The browser updates the hash
// before that focus and fires `hashchange` only afterwards, which is the order
// used here.
function jumpTo(p, id) {
  p.window.location.hash = "#" + id;
  p.link.fire("focus");
  p.window.fire("hashchange");
}


test("the popup is skipped for the focus that follows a jump", () => {
  const p = citationPage();
  jumpTo(p, "GoerzQ2022-cite-1");
  assert.ok(!popupShown(p), "a backlink must not open the popup of its own entry");
});


test("tabbing back to the citation still shows the popup", () => {
  // Only the focus caused by the jump is skipped. The `hashchange` that the
  // jump itself fires must not reset that, or the next focus is skipped too.
  const p = citationPage();
  jumpTo(p, "GoerzQ2022-cite-1");
  p.link.fire("blur");
  p.link.fire("focus");
  assert.ok(popupShown(p), "the popup must be shown when focusing the link again");
});


test("returning to the citation later counts as a jump again", () => {
  const p = citationPage();
  jumpTo(p, "GoerzQ2022-cite-1");
  // The reader moves on to some other part of the page ...
  p.window.location.hash = "#Some-Section";
  p.window.fire("hashchange");
  // ... and then follows the backlink to the same citation once more
  jumpTo(p, "GoerzQ2022-cite-1");
  assert.ok(!popupShown(p), "the second jump must skip the popup as well");
});


let failed = 0;
tests.forEach(([name, fn]) => {
  try {
    fn();
    console.log("PASS: " + name);
  } catch (e) {
    failed += 1;
    console.log("FAIL: " + name);
    console.log("      " + (e && e.message ? e.message.split("\n").join("\n      ") : e));
  }
});
console.log(`${tests.length - failed} of ${tests.length} tests passed`);
process.exit(failed === 0 ? 0 : 1);
