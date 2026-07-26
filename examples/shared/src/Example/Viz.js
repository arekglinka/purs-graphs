export function setInnerHTMLById(id) {
  return (html) => () => {
    const el = document.getElementById(id);
    if (el) {
      el.innerHTML = html;
    }
  };
}
