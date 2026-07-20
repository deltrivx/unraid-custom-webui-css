/*! apps-enhancement.js
 * unraid-custom-webui-css v1.7.0 merged enhancement
 * - body.ucwc-<route> class sync (Apps isolation / page-scoped CSS)
 * - Apps mobile/desktop menu show/close patch
 * - CA search suggestions mount + rAF positioning
 * Single init guard; no 2s polling.
 */
(function () {
  "use strict";

  if (window.__unraidCustomWebuiCssAppsEnhancement) return;
  window.__unraidCustomWebuiCssAppsEnhancement = true;

  var PATCHED = false;
  var menuScrollPosition = 0;
  var suggestRafId = 0;
  var pendingRoute = false;

  var ROUTES = {
    "/Apps": "ucwc-apps",
    "/Main": "ucwc-main",
    "/Shares": "ucwc-shares",
    "/Docker": "ucwc-docker",
    "/Plugins": "ucwc-plugins",
    "/VMs": "ucwc-vms",
    "/Settings": "ucwc-settings",
    "/Tools": "ucwc-tools",
    "/Dashboard": "ucwc-dashboard",
    "/Users": "ucwc-users"
  };
  var ALL_CLASSES = Object.keys(ROUTES).map(function (k) {
    return ROUTES[k];
  });

  function activeRouteClass() {
    try {
      var active = document.querySelector("#menu .nav-item.active a[href]");
      if (!active) return null;
      var href = active.getAttribute("href") || "";
      for (var k in ROUTES) {
        if (Object.prototype.hasOwnProperty.call(ROUTES, k)) {
          if (href === k || href.indexOf(k + "/") === 0) return ROUTES[k];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  function syncRouteClass() {
    try {
      var wanted = activeRouteClass();
      var cl = document.body.classList;
      for (var i = 0; i < ALL_CLASSES.length; i++) {
        var c = ALL_CLASSES[i];
        if (c !== wanted && cl.contains(c)) cl.remove(c);
      }
      if (wanted && !cl.contains(wanted)) cl.add(wanted);
      return wanted;
    } catch (e) {
      return null;
    }
  }

  function isAppsPage() {
    return activeRouteClass() === "ucwc-apps";
  }

  function isMobileAppsViewport() {
    try {
      return window.matchMedia && window.matchMedia("(max-width: 767px)").matches;
    } catch (e) {
      return window.innerWidth <= 767;
    }
  }

  function scheduleSync() {
    if (pendingRoute) return;
    pendingRoute = true;
    var run = function () {
      pendingRoute = false;
      syncRouteClass();
    };
    if (window.requestIdleCallback) {
      requestIdleCallback(run, { timeout: 200 });
    } else {
      setTimeout(run, 0);
    }
  }

  function hideMasks() {
    try {
      var sels = [".mobileOverlay", ".menuOverlay", ".ca_overlay", ".sidebarOverlay", ".menu_overlay"];
      for (var i = 0; i < sels.length; i++) {
        var nodes = document.querySelectorAll(sels[i]);
        for (var j = 0; j < nodes.length; j++) {
          var el = nodes[j];
          if (el.classList && el.classList.contains("swal-overlay")) continue;
          el.style.setProperty("display", "none", "important");
          el.style.setProperty("pointer-events", "none", "important");
          el.style.setProperty("opacity", "0", "important");
        }
      }
    } catch (e) {}
  }

  function unlockPage() {
    try {
      document.documentElement.style.setProperty("--mainAreaHeight", "unset");
      document.documentElement.style.overflow = "";
      document.documentElement.style.height = "";
      document.body.classList.remove("body_sidebarScroll");
      document.body.style.overflow = "";
      document.body.style.height = "";
      document.body.style.position = "";
      document.body.style.top = "";
      hideMasks();
    } catch (e) {}
  }

  function showMenuNoJump() {
    if (!isAppsPage()) {
      if (typeof window.__ca_showMenu_orig === "function") {
        return window.__ca_showMenu_orig.apply(this, arguments);
      }
      return;
    }
    if (!isMobileAppsViewport()) {
      try {
        if (window.jQuery) {
          window.jQuery(".mobileMenu, #mobileMenu").show().css({ display: "block", width: "", height: "", overflow: "" });
          window.jQuery(".mobileMenu .menuItems, #mobileMenu .menuItems, .menuItems").show();
        }
        document.body.classList.remove("menuHidden");
        document.body.classList.add("menuShowing");
      } catch (e) {}
      unlockPage();
      return;
    }
    try {
      if (window.jQuery) {
        window.jQuery(".menuAdjust,.hideWithMenu").addClass("menuShowing").removeClass("menuHidden");
        var $menu = window.jQuery(".mobileMenu, #mobileMenu");
        $menu.stop(true, true);
        $menu.removeClass("menuHidden").addClass("menuShowing").show();
        $menu.css({ left: "", top: "", width: "", height: "", overflow: "", display: "block" });
        window.jQuery(".mobileMenu .menuItems, #mobileMenu .menuItems").css({
          maxHeight: "none",
          height: "auto",
          overflow: "visible"
        });
      } else {
        document.querySelectorAll(".menuAdjust,.hideWithMenu").forEach(function (el) {
          el.classList.add("menuShowing");
          el.classList.remove("menuHidden");
        });
        document.querySelectorAll(".mobileMenu, #mobileMenu").forEach(function (el) {
          el.classList.remove("menuHidden");
          el.classList.add("menuShowing");
          el.style.display = "block";
          el.style.maxHeight = "none";
          el.style.overflow = "visible";
        });
      }
      document.body.classList.add("menuShowing");
      document.body.classList.remove("menuHidden");
    } catch (e) {}
    unlockPage();
    if (window.requestAnimationFrame) {
      requestAnimationFrame(function () {
        unlockPage();
      });
    }
  }

  function closeMenuNoJump() {
    if (!isAppsPage()) {
      if (typeof window.__ca_closeMenu_orig === "function") {
        return window.__ca_closeMenu_orig.apply(this, arguments);
      }
      return;
    }
    if (!isMobileAppsViewport()) {
      try {
        if (window.jQuery) {
          window.jQuery(".mobileMenu, #mobileMenu").show().css({ display: "block", width: "", height: "", overflow: "" });
          window.jQuery(".mobileMenu .menuItems, #mobileMenu .menuItems, .menuItems").show();
        }
        document.body.classList.remove("menuHidden");
        document.body.classList.add("menuShowing");
      } catch (e) {}
      unlockPage();
      return;
    }
    try {
      if (window.jQuery) {
        window.jQuery(".menuAdjust,.hideWithMenu").addClass("menuHidden").removeClass("menuShowing");
        var $menu = window.jQuery(".mobileMenu, #mobileMenu");
        $menu.stop(true, true);
        $menu.removeClass("menuShowing").addClass("menuHidden").hide();
      } else {
        document.querySelectorAll(".menuAdjust,.hideWithMenu").forEach(function (el) {
          el.classList.add("menuHidden");
          el.classList.remove("menuShowing");
        });
        document.querySelectorAll(".mobileMenu, #mobileMenu").forEach(function (el) {
          el.classList.remove("menuShowing");
          el.classList.add("menuHidden");
          el.style.display = "none";
        });
      }
      document.body.classList.remove("menuShowing");
      document.body.classList.add("menuHidden");
    } catch (e) {}
    unlockPage();
  }

  function patchMenus() {
    if (PATCHED) return true;
    if (typeof window.showMenu !== "function" || typeof window.closeMenu !== "function") {
      return false;
    }
    if (window.showMenu.__appsSidebarFix) return true;
    window.__ca_showMenu_orig = window.showMenu;
    window.__ca_closeMenu_orig = window.closeMenu;
    window.showMenu = showMenuNoJump;
    window.closeMenu = closeMenuNoJump;
    window.showMenu.__appsSidebarFix = true;
    window.closeMenu.__appsSidebarFix = true;
    PATCHED = true;
    return true;
  }

  function bootMenus() {
    if (patchMenus()) return;
    var n = 0;
    var timer = setInterval(function () {
      n += 1;
      if (patchMenus() || n > 40) clearInterval(timer);
    }, 300);
  }

  function bootClassSync() {
    syncRouteClass();
    document.addEventListener(
      "click",
      function (ev) {
        var t = ev.target;
        if (!t || !t.closest) return;
        if (t.closest("#menu, .nav-item, a[href^=\"/\"]")) {
          scheduleSync();
        }
      },
      true
    );
    window.addEventListener("popstate", scheduleSync);
    window.addEventListener("hashchange", scheduleSync);
    try {
      var menu = document.getElementById("menu") || document.querySelector("#menu");
      if (menu && window.MutationObserver) {
        var mo = new MutationObserver(scheduleSync);
        mo.observe(menu, { attributes: true, attributeFilter: ["class"], childList: true, subtree: false });
        var items = menu.querySelectorAll(".nav-item");
        for (var i = 0; i < items.length; i++) {
          mo.observe(items[i], { attributes: true, attributeFilter: ["class"] });
        }
      }
    } catch (e) {}
  }

  /* ===== Search suggestions (from v1.6.1 apps-enhancement) ===== */
  function searchBox() {
    return document.getElementById("searchBox");
  }

  function suggestionList() {
    var box = searchBox();
    var listId = box && box.getAttribute("aria-owns");
    return listId ? document.getElementById(listId) : null;
  }

  function mountSuggestions() {
    var list = suggestionList();
    if (!list) return null;
    list.classList.add("caSearchSuggestions");
    if (list.parentNode !== document.body) document.body.appendChild(list);
    list.style.setProperty("box-sizing", "border-box", "important");
    list.style.setProperty("margin", "0", "important");
    list.style.setProperty("padding", "0", "important");
    return list;
  }

  function positionSuggestions() {
    if (!isAppsPage()) return;
    var box = searchBox();
    var list = mountSuggestions();
    if (!box || !list) return;
    var rect = box.getBoundingClientRect();
    var edge = 10;
    var width = Math.min(rect.width, window.innerWidth - edge * 2);
    var viewportLeft = Math.max(edge, Math.min(rect.left, window.innerWidth - width - edge));
    document.documentElement.style.setProperty("--ca-suggest-left", viewportLeft + window.scrollX + "px");
    document.documentElement.style.setProperty("--ca-suggest-top", rect.bottom + window.scrollY + 3 + "px");
    document.documentElement.style.setProperty("--ca-suggest-width", width + "px");
    list.style.setProperty("width", width + "px", "important");
    list.style.setProperty("min-width", width + "px", "important");
    list.style.setProperty("max-width", width + "px", "important");
  }

  function schedulePositionSuggestions() {
    if (suggestRafId) return;
    suggestRafId = window.requestAnimationFrame(function () {
      suggestRafId = 0;
      positionSuggestions();
    });
  }

  function bootSuggestions() {
    if (!isAppsPage() || !searchBox()) return false;
    var box = searchBox();
    if (box.__ucwcSuggestBound) return true;
    box.__ucwcSuggestBound = true;
    box.addEventListener("awesomplete-open", schedulePositionSuggestions);
    box.addEventListener("input", schedulePositionSuggestions);
    var searchArea = document.querySelector(".searchArea");
    if (searchArea) searchArea.addEventListener("scroll", schedulePositionSuggestions, { passive: true });
    window.addEventListener("resize", schedulePositionSuggestions, { passive: true });
    window.setTimeout(mountSuggestions, 0);
    return true;
  }

  function bootSuggestionsRetry() {
    if (bootSuggestions()) return;
    var attempts = 0;
    var timer = window.setInterval(function () {
      attempts += 1;
      if (bootSuggestions() || attempts >= 100) window.clearInterval(timer);
    }, 100);
  }

  function boot() {
    bootClassSync();
    bootMenus();
    bootSuggestionsRetry();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
