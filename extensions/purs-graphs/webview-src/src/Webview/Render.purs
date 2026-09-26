-- | Renderers for the two preview kinds.
-- |
-- | DOT previews go through purs-viz (Graphviz WASM) and reuse `extractSvg`
-- | to strip the XML prologue. JSON graph previews run dagre layout via
-- | `buildAndLayout` and emit a plain SVG string styled by `pg-*` CSS classes
-- | defined in the extension host's webview HTML.
module Webview.Render
  ( renderDot
  , renderGraph
  , engineFromString
  ) where

import Prelude

import Dagre.Graph (NodeOptions)
import Data.Argonaut.Parser (jsonParser)
import Data.Array (mapMaybe)
import Data.Either (Either(..))
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String.Common as SC
import Data.String.Pattern (Pattern(..), Replacement(..))
import Effect (Effect)
import Example.DagreRun (buildAndLayout)
import Example.Viz (extractSvg)
import Viz (VizInstance)
import Viz.Render (Engine(..), renderString)
import Webview.GraphSpec (GraphSpec, NodeSpec, decodeSpec)

-- | Parse a Graphviz engine name; unknown names fall back to `Dot` upstream.
engineFromString :: String -> Maybe Engine
engineFromString = case _ of
  "dot" -> Just Dot
  "neato" -> Just Neato
  "fdp" -> Just Fdp
  "circo" -> Just Circo
  "twopi" -> Just Twopi
  _ -> Nothing

-- | Render DOT source to an SVG string (XML prologue stripped).
renderDot :: VizInstance -> String -> String -> Either (Array String) String
renderDot viz source engine =
  map extractSvg
    ( renderString viz source
        (Just { format: "svg", engine: fromMaybe Dot (engineFromString engine) })
    )

-- | Parse the `*.graph.json` source, lay it out with dagre, and emit an SVG
-- | string. Positions are node centers; everything is shifted by the padding
-- | so nothing clips.
renderGraph :: String -> Effect (Either (Array String) String)
renderGraph source = case jsonParser source of
  Left err -> pure $ Left [ "invalid JSON: " <> err ]
  Right json -> case decodeSpec json of
    Left err -> pure $ Left [ "invalid graph spec: " <> err ]
    Right spec -> do
      layout <-
        buildAndLayout (map toNodeOptions spec.nodes) (map toEdge spec.edges) spec.rankDir
      pure $ Right $ layoutToSvg spec layout.positions layout.dims

toNodeOptions :: NodeSpec -> NodeOptions
toNodeOptions n = { id: n.id, width: n.width, height: n.height, label: n.label }

toEdge :: forall r. { from :: String, to :: String | r } -> { source :: String, target :: String }
toEdge e = { source: e.from, target: e.to }

pad :: Number
pad = 20.0

layoutToSvg
  :: GraphSpec
  -> Map String { x :: Number, y :: Number }
  -> Maybe { width :: Number, height :: Number }
  -> String
layoutToSvg spec positions dims =
  let
    w = fromMaybe 800.0 ((_ + pad * 2.0) <<< _.width <$> dims)
    h = fromMaybe 600.0 ((_ + pad * 2.0) <<< _.height <$> dims)
    edges = mapMaybe (edgeToLine positions) spec.edges
    nodes = mapMaybe (nodeToSvg positions) spec.nodes
  in
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " <> num w <> " " <> num h
      <> "\" width=\""
      <> num w
      <> "\" height=\""
      <> num h
      <> "\">"
      <> SC.joinWith "" edges
      <> SC.joinWith "" nodes
      <> "</svg>"

edgeToLine
  :: Map String { x :: Number, y :: Number }
  -> forall r
   . { from :: String, to :: String | r }
  -> Maybe String
edgeToLine positions e = case Map.lookup e.from positions, Map.lookup e.to positions of
  Just a, Just b ->
    Just
      ( "<line class=\"pg-edge\" x1=\"" <> num (a.x + pad) <> "\" y1=\"" <> num (a.y + pad)
          <> "\" x2=\""
          <> num (b.x + pad)
          <> "\" y2=\""
          <> num (b.y + pad)
          <> "\"/>"
      )
  _, _ -> Nothing

nodeToSvg :: Map String { x :: Number, y :: Number } -> NodeSpec -> Maybe String
nodeToSvg positions n = case Map.lookup n.id positions of
  Just p ->
    Just
      ( "<rect class=\"pg-node\" x=\"" <> num (p.x + pad - n.width / 2.0)
          <> "\" y=\""
          <> num (p.y + pad - n.height / 2.0)
          <> "\" width=\""
          <> num n.width
          <> "\" height=\""
          <> num n.height
          <> "\" rx=\"6\"/>"
          <> "<text class=\"pg-label\" x=\""
          <> num (p.x + pad)
          <> "\" y=\""
          <> num (p.y + pad)
          <> "\">"
          <> escapeXml n.label
          <> "</text>"
      )
  Nothing -> Nothing

num :: Number -> String
num = show

escapeXml :: String -> String
escapeXml =
  SC.replaceAll (Pattern "'") (Replacement "&#39;")
    <<< SC.replaceAll (Pattern "\"") (Replacement "&quot;")
    <<< SC.replaceAll (Pattern ">") (Replacement "&gt;")
    <<< SC.replaceAll (Pattern "<") (Replacement "&lt;")
    <<< SC.replaceAll (Pattern "&") (Replacement "&amp;")
