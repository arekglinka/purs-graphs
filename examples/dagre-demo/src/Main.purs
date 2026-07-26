-- | dagre-demo: a Halogen app that lays out a 5-node build-pipeline graph
-- | using purs-dagre and renders it as SVG via the Halogen HTML DSL.
module Main where

import Prelude

import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse, traverse_)
import Data.Tuple (Tuple(..))
import Dagre.Graph
  ( Graph
  , NodeOptions
  , RankDir(..)
  , layout
  , new
  , nodeIds
  , nodePosition
  , setEdge
  , setNode
  , setRankDir
  ) as Dagre
import Effect (Effect)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)

type Position = { x :: Number, y :: Number }

-- | The canonical build-pipeline graph shared by both examples.
pipelineNodes :: Array Dagre.NodeOptions
pipelineNodes =
  [ { id: "source", width: 120.0, height: 50.0, label: "source" }
  , { id: "compile", width: 120.0, height: 50.0, label: "compile" }
  , { id: "link", width: 120.0, height: 50.0, label: "link" }
  , { id: "test", width: 120.0, height: 50.0, label: "test" }
  , { id: "package", width: 120.0, height: 50.0, label: "package" }
  ]

pipelineEdges :: Array { source :: String, target :: String }
pipelineEdges =
  [ { source: "source", target: "compile" }
  , { source: "compile", target: "link" }
  , { source: "link", target: "test" }
  , { source: "test", target: "package" }
  ]

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI component unit body

component :: forall q i o m. H.Component q i o m
component = Hooks.component \_ _ -> Hooks.do
  positions /\ positionsId <-
    Hooks.useState (Nothing :: Maybe (Map String Position))

  Hooks.useLifecycleEffect do
    g <- liftEffect buildAndLayout
    ids <- liftEffect $ Dagre.nodeIds g
    entries <- liftEffect $ traverse (\id -> Tuple id <$> fromMaybePos id g) ids
    Hooks.put positionsId (Just (Map.fromFoldable entries))
    pure Nothing

  Hooks.pure case positions of
    Nothing ->
      HH.div_ [ HH.h1_ [ HH.text "Computing layout..." ] ]
    Just pm ->
      HH.div_
        [ HH.h1_ [ HH.text "dagre-demo — Build Pipeline Layout" ]
        , HH.p_ [ HH.text "A 5-node directed graph laid out by dagre, rendered as SVG." ]
        , renderSvg pm
        ]

fromMaybePos :: String -> Dagre.Graph -> Effect Position
fromMaybePos id g = do
  mp <- Dagre.nodePosition id g
  pure case mp of
    Just p -> p
    Nothing -> { x: 0.0, y: 0.0 }

buildAndLayout :: Effect Dagre.Graph
buildAndLayout = do
  g <- Dagre.new
  Dagre.setRankDir Dagre.TopBottom g
  traverse_ (\n -> Dagre.setNode n g) pipelineNodes
  traverse_ (\e -> Dagre.setEdge e g) pipelineEdges
  Dagre.layout g
  pure g

-- SVG rendering

svgNS :: H.Namespace
svgNS = H.Namespace "http://www.w3.org/2000/svg"

svgEl :: forall w i. String -> Array (HH.IProp w i) -> Array (HH.HTML w i) -> HH.HTML w i
svgEl name = HH.elementNS svgNS (H.ElemName name)

svgAttr :: forall r i. String -> String -> HH.IProp r i
svgAttr k = HH.attr (HH.AttrName k)

renderSvg :: forall w i. Map String Position -> HH.HTML w i
renderSvg pm =
  svgEl "svg"
    [ svgAttr "width" "400"
    , svgAttr "height" "350"
    , svgAttr "viewBox" "0 0 400 350"
    ]
    (map (renderEdge pm) pipelineEdges <> map renderNode (Map.toUnfoldable pm))

renderNode :: forall w i. Tuple String Position -> HH.HTML w i
renderNode (Tuple label { x, y }) =
  svgEl "g" []
    [ svgEl "rect"
        [ svgAttr "x" (show (x - 60.0))
        , svgAttr "y" (show (y - 25.0))
        , svgAttr "width" "120"
        , svgAttr "height" "50"
        , svgAttr "rx" "8"
        , svgAttr "fill" "#e3f2fd"
        , svgAttr "stroke" "#1976d2"
        ]
        []
    , svgEl "text"
        [ svgAttr "x" (show x)
        , svgAttr "y" (show (y + 5.0))
        , svgAttr "text-anchor" "middle"
        , svgAttr "font-family" "sans-serif"
        , svgAttr "font-size" "14"
        ]
        [ HH.text label ]
    ]

renderEdge
  :: forall w i
   . Map String Position
  -> { source :: String, target :: String }
  -> HH.HTML w i
renderEdge pm { source, target } =
  case Map.lookup source pm, Map.lookup target pm of
    Just s, Just t ->
      svgEl "line"
        [ svgAttr "x1" (show s.x)
        , svgAttr "y1" (show s.y)
        , svgAttr "x2" (show t.x)
        , svgAttr "y2" (show t.y)
        , svgAttr "stroke" "#999"
        , svgAttr "stroke-width" "2"
        ]
        []
    _, _ -> HH.text ""
