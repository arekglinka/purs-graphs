// Graphviz SVG wraps each node in <g class="node"><title>NODE_ID</title>...</g>.
// Walk up from click target to find the enclosing g.node, then read its <title>.
export function getClickedNodeId(event) {
  let target = event.target;
  while (target && target.tagName !== "g") {
    target = target.parentElement;
  }
  if (target?.classList?.contains("node")) {
    const title = target.querySelector("title");
    return title ? title.textContent : "";
  }
  return "";
}
