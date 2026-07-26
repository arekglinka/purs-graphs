export function setInnerHTMLById(id) {
  return function (html) {
    return function () {
      var el = document.getElementById(id);
      if (el) { el.innerHTML = html; }
    };
  };
}
