/* A minimal fake DOM for testing the bundled browser assets.
 *
 * It implements just enough of `window` and `document` to evaluate the scripts
 * in `assets/` unchanged and to drive their event handlers, so that the tests
 * in `test_assets.js` exercise the shipped files instead of a copy of their
 * logic. Everything here is a stub: nothing is laid out, and only the event
 * types that the scripts listen for are dispatched.
 */
"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const ASSETS = path.join(__dirname, "..", "..", "assets");

// An element. `props` may set `id`, `href` (from which `hash` is derived, as
// in a browser), and `children`.
function element(tag, props) {
  props = props || {};
  const e = {
    tagName: tag.toUpperCase(),
    id: props.id || "",
    parentNode: null,
    childNodes: [],
    style: {},
    offsetWidth: 100,
    offsetHeight: 50,
    handlers: {},
    classes: [],
    attributes: {},
  };
  e.href = props.href || "";
  // As in a browser, where an empty fragment gives an empty `hash`: this is
  // what distinguishes a citation from Documenter's `href="#"` controls
  const fragment = e.href.indexOf("#");
  e.hash = fragment === -1 || fragment === e.href.length - 1 ? "" : e.href.slice(fragment);
  e.classList = {
    add: (c) => {
      if (!e.classes.includes(c)) e.classes.push(c);
    },
    remove: (c) => {
      e.classes = e.classes.filter((x) => x !== c);
    },
    contains: (c) => e.classes.includes(c),
  };
  e.setAttribute = (name, value) => {
    e.attributes[name] = value;
  };
  e.removeAttribute = (name) => {
    delete e.attributes[name];
  };
  e.getAttribute = (name) => (name in e.attributes ? e.attributes[name] : null);
  e.addEventListener = (type, fn) => {
    (e.handlers[type] = e.handlers[type] || []).push(fn);
  };
  e.appendChild = (child) => {
    child.parentNode = e;
    e.childNodes.push(child);
    return child;
  };
  e.getBoundingClientRect = () => ({ top: 10, bottom: 30, left: 10, right: 60 });
  e.querySelectorAll = () => [];
  e.fire = (type, event) => {
    (e.handlers[type] || []).forEach((fn) =>
      fn(Object.assign({ currentTarget: e, target: e }, event))
    );
  };
  (props.children || []).forEach((child) => e.appendChild(child));
  return e;
}

// A page. `backlinks` are the elements returned for the selector that
// `citations-backlinks.js` uses, `links` those in `document.links`, which is
// what `citations-hover.js` walks.
function page(options) {
  options = options || {};
  const store = {};
  const window = {
    innerWidth: 1000,
    innerHeight: 800,
    scrollX: 0,
    scrollY: 0,
    location: { hash: options.hash || "" },
    sessionStorage: {
      getItem: (key) => (key in store ? store[key] : null),
      setItem: (key, value) => {
        store[key] = String(value);
      },
    },
    handlers: {},
    addEventListener: (type, fn) => {
      (window.handlers[type] = window.handlers[type] || []).push(fn);
    },
    fire: (type, event) => {
      (window.handlers[type] || []).forEach((fn) => fn(event || {}));
    },
  };
  const document = {
    readyState: "complete",
    body: element("body"),
    links: options.links || [],
    currentScript: { src: options.scriptSrc || "" },
    handlers: {},
    addEventListener: (type, fn) => {
      (document.handlers[type] = document.handlers[type] || []).push(fn);
    },
    fire: (type, event) => {
      (document.handlers[type] || []).forEach((fn) => fn(event || {}));
    },
    createElement: (tag) => element(tag),
    querySelectorAll: (selector) => {
      if (selector === ".citation-backlinks a") return options.backlinks || [];
      return [];
    },
  };
  if (options.hoverData) window.DocumenterCitationsHoverData = options.hoverData;
  return { window, document, storage: store };
}

// Evaluate one of the bundled assets in the given page, as a browser would
function load(filename, page) {
  const source = fs.readFileSync(path.join(ASSETS, filename), "utf8");
  const sandbox = {
    window: page.window,
    document: page.document,
    URL: URL,
    console: console,
    setTimeout: setTimeout,
    clearTimeout: clearTimeout,
  };
  vm.runInNewContext(source, vm.createContext(sandbox), { filename: filename });
  return page;
}

module.exports = { element, page, load };
