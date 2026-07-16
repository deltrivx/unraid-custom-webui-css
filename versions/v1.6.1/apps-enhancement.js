(function () {
  'use strict';

  if (window.__unraidCustomWebuiCssAppsEnhancement) return;
  window.__unraidCustomWebuiCssAppsEnhancement = true;

  var menuScrollPosition = 0;
  var rafId = 0;

  function isAppsPage() {
    return Boolean(document.querySelector('#menu .nav-item.active a[href="/Apps"]'));
  }

  function searchBox() {
    return document.getElementById('searchBox');
  }

  function suggestionList() {
    var box = searchBox();
    var listId = box && box.getAttribute('aria-owns');
    return listId ? document.getElementById(listId) : null;
  }

  function mountSuggestions() {
    var list = suggestionList();
    if (!list) return null;
    list.classList.add('caSearchSuggestions');
    if (list.parentNode !== document.body) document.body.appendChild(list);
    list.style.setProperty('box-sizing', 'border-box', 'important');
    list.style.setProperty('margin', '0', 'important');
    list.style.setProperty('padding', '0', 'important');
    return list;
  }

  function positionSuggestions() {
    var box = searchBox();
    var list = mountSuggestions();
    if (!box || !list) return;

    var rect = box.getBoundingClientRect();
    var edge = 10;
    var width = Math.min(rect.width, window.innerWidth - edge * 2);
    var viewportLeft = Math.max(edge, Math.min(rect.left, window.innerWidth - width - edge));

    document.documentElement.style.setProperty('--ca-suggest-left', viewportLeft + window.scrollX + 'px');
    document.documentElement.style.setProperty('--ca-suggest-top', rect.bottom + window.scrollY + 3 + 'px');
    document.documentElement.style.setProperty('--ca-suggest-width', width + 'px');
    list.style.setProperty('width', width + 'px', 'important');
    list.style.setProperty('min-width', width + 'px', 'important');
    list.style.setProperty('max-width', width + 'px', 'important');
  }

  function schedulePositionSuggestions() {
    if (rafId) return;
    rafId = window.requestAnimationFrame(function () {
      rafId = 0;
      positionSuggestions();
    });
  }

  function showMenu() {
    menuScrollPosition = window.scrollY;
    $('.menuAdjust,.hideWithMenu').addClass('menuShowing').removeClass('menuHidden');
    $('.mobileMenu').stop(true, true).removeAttr('style').show();
    document.documentElement.style.setProperty('--mainAreaHeight', $('.mobileMenu').height() + 'px');
  }

  function closeMenu() {
    $('.menuAdjust,.hideWithMenu').addClass('menuHidden').removeClass('menuShowing');
    $('.mobileMenu').stop(true, true).removeAttr('style').hide();
    window.scrollTo(window.scrollX, menuScrollPosition);
    document.documentElement.style.setProperty('--mainAreaHeight', 'unset');
  }

  function initialise() {
    if (!isAppsPage() || !window.jQuery || !searchBox()) return false;

    var box = searchBox();
    box.addEventListener('awesomplete-open', schedulePositionSuggestions);
    box.addEventListener('input', schedulePositionSuggestions);

    var searchArea = document.querySelector('.searchArea');
    if (searchArea) searchArea.addEventListener('scroll', schedulePositionSuggestions, { passive: true });
    window.addEventListener('resize', schedulePositionSuggestions, { passive: true });

    window.showMenu = showMenu;
    window.closeMenu = closeMenu;
    window.setTimeout(mountSuggestions, 0);
    return true;
  }

  if (!initialise()) {
    var attempts = 0;
    var timer = window.setInterval(function () {
      attempts += 1;
      if (initialise() || attempts >= 100) window.clearInterval(timer);
    }, 100);
  }
})();
