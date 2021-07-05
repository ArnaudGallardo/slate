//= require ./lib/_energize
//= require ./app/_copy
//= require ./app/_toc
//= require ./app/_lang
//= require ./lib/perfect-scrollbar

$(function() {
  loadToc($('#toc'), '.toc-link', '.toc-list-h2', 10);
  setupLanguages($('body').data('languages'));
  $('.content').imagesLoaded( function() {
    window.recacheHeights();
    window.refreshToc();
  });
  // Add Perfect Scrollbar to examples
  let tabs = [];
  $('.tabs').each(function(){ tabs.push(new PerfectScrollbar($(this)[0])); });
  $(window).resize(function() {
    tabs.forEach((tab) => {
      tab.update();
    });
  });
  $(window).on('language-selected', function() {
    for (const tab of tabs) {
      tab.update();
    }
  });
});

window.onpopstate = function() {
  activateLanguage(getLanguageFromQueryString());
};
