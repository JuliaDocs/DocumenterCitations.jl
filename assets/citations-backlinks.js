/* Marking the backlink that leads back to the citation the reader came from —
 * DocumenterCitations.
 *
 * Every citation link carries the `id` that the backlinks at the end of the
 * corresponding bibliography entry point to. Following a citation therefore
 * identifies one particular backlink, but the browser cannot express that: the
 * link targets the entry as a whole, and nothing in the resulting page says
 * which of the entry's backlinks is the way back.
 *
 * So the id of the followed citation is remembered in `sessionStorage` (the
 * bibliography is usually on a different page, which rules out passing it in a
 * variable), and the backlink pointing to it is given the class
 * `is-current-citation`, styled in `citations.css`. Without JavaScript, or
 * when the reader arrives at the bibliography by other means, the backlinks
 * are simply all shown alike.
 */
(function () {
  "use strict";

  var CLASS = "is-current-citation";
  var STORAGE_KEY = "documentercitations-followed-citation";

  var marked = null; // the backlink currently carrying the class

  // `sessionStorage` throws in a browser that blocks storage, and is absent
  // for a page opened from the file system in some browsers
  function readFollowed() {
    try {
      return window.sessionStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return null;
    }
  }

  function writeFollowed(id) {
    try {
      window.sessionStorage.setItem(STORAGE_KEY, id);
    } catch (e) {
      /* not being able to remember it only means no backlink is marked */
    }
  }

  function unmark() {
    if (marked) {
      marked.classList.remove(CLASS);
      marked = null;
    }
  }

  // Mark the backlink that points at the citation with the given id, if the
  // page has one. Any id that no backlink refers to is ignored, which is what
  // keeps this from reacting to unrelated links.
  function mark(id) {
    unmark();
    if (!id) return;
    var backlinks = document.querySelectorAll(".citation-backlinks a");
    for (var i = 0; i < backlinks.length; i++) {
      if (backlinks[i].hash === "#" + id) {
        backlinks[i].classList.add(CLASS);
        marked = backlinks[i];
        return;
      }
    }
  }

  function init() {
    // A click on a citation records where to come back to. The link is not
    // checked for being a citation: `mark` only reacts to an id that some
    // backlink points at.
    document.addEventListener("click", function (e) {
      var element = e.target;
      while (element && element !== document) {
        if (element.tagName === "A") {
          if (element.id) {
            writeFollowed(element.id);
            // With the bibliography on the same page as the citation there is
            // no page load that would pick the id up again
            mark(element.id);
          }
          return;
        }
        element = element.parentNode;
      }
    });
    mark(readFollowed());
    // Following a backlink, or any other jump within the page, leaves the mark
    // in place: it still shows where the reader came from
    window.addEventListener("pageshow", function () {
      mark(readFollowed());
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
