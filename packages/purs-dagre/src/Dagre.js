// dagre is an npm peer-dependency (dagre@0.8.5). Consumers must install it;
// it is NOT bundled here so the dependency can be deduped across the tree.
import dagre from "dagre";

export function newGraph() {
  var g = new dagre.graphlib.Graph();
  g.setGraph({});
  g.setDefaultEdgeLabel(function () { return {}; });
  return g;
}

export function setRankDir(g) {
  return function (dir) {
    return function () {
      var label = g.graph();
      if (label) { label.rankdir = dir; }
    };
  };
}

export function setNodeImpl(g) {
  return function (id) {
    return function (dims) {
      return function (labelText) {
        return function () {
          g.setNode(id, {
            width: dims.width,
            height: dims.height,
            label: labelText
          });
        };
      };
    };
  };
}

export function setEdgeImpl(g) {
  return function (source) {
    return function (target) {
      return function () {
        g.setEdge(source, target, {});
      };
    };
  };
}

export function layoutImpl(g) {
  return function () {
    dagre.layout(g);
  };
}

export function nodeX(g) {
  return function (id) {
    return function () {
      var node = g.node(id);
      return node ? node.x : null;
    };
  };
}

export function nodeY(g) {
  return function (id) {
    return function () {
      var node = g.node(id);
      return node ? node.y : null;
    };
  };
}

export function nodes(g) {
  return function () {
    return g.nodes();
  };
}

export function graphWidth(g) {
  return function () {
    var label = g.graph();
    return label ? label.width : null;
  };
}

export function graphHeight(g) {
  return function () {
    var label = g.graph();
    return label ? label.height : null;
  };
}
