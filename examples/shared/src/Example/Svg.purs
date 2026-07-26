-- | Halogen SVG element helpers.
-- |
-- | These wrap `HH.elementNS` for the SVG namespace so callers don't have to
-- | repeat the namespace boilerplate. Pure presentation primitives — no
-- | application logic.
module Example.Svg
  ( arrowheadDefs
  , cn
  , svgAttr
  , svgEl
  ) where

import Halogen as H
import Halogen.HTML as HH

svgNS :: H.Namespace
svgNS = H.Namespace "http://www.w3.org/2000/svg"

-- | Create an SVG element with the given tag, attributes, and children.
svgEl :: forall r i w. String -> Array (HH.IProp r i) -> Array (HH.HTML w i) -> HH.HTML w i
svgEl name = HH.elementNS svgNS (H.ElemName name)

-- | Set an SVG presentation attribute by name.
svgAttr :: forall r i. String -> String -> HH.IProp r i
svgAttr k = HH.attr (HH.AttrName k)

-- | Wrap a Tailwind utility string as a Halogen `ClassName`.
-- | Used everywhere: `HP.class_ (cn "flex gap-4")`.
cn :: String -> HH.ClassName
cn = HH.ClassName

-- | SVG `<defs>` block defining a triangular `#arrowhead` marker.
-- | Reference via `svgAttr "marker-end" "url(#arrowhead)"`.
arrowheadDefs :: forall w i. HH.HTML w i
arrowheadDefs =
  svgEl "defs"
    []
    [ svgEl "marker"
        [ svgAttr "id" "arrowhead"
        , svgAttr "markerWidth" "10"
        , svgAttr "markerHeight" "7"
        , svgAttr "refX" "9"
        , svgAttr "refY" "3.5"
        , svgAttr "orient" "auto"
        ]
        [ svgEl "polygon" [ svgAttr "points" "0 0, 10 3.5, 0 7", svgAttr "fill" "#999" ] [] ]
    ]
