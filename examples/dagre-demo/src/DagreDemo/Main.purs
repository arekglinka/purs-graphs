-- | dagre-demo: an interactive graph layout playground using purs-dagre.
-- |
-- | Users can add/remove nodes and edges, change rank direction, and see the
-- | layout update live. SVG auto-sizes to the computed graph dimensions.
module DagreDemo.Main where

import Prelude

import Data.Array (filter, length, (:))
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Traversable (traverse, traverse_)
import Data.Tuple (Tuple(..))
import Dagre.Graph
  ( Graph
  , NodeOptions
  , RankDir(..)
  , dimensions
  , layout
  , new
  , nodeIds
  , nodePosition
  , setEdge
  , setNode
  , setRankDir
  ) as Dagre
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)

type Position = { x :: Number, y :: Number }

type State =
  { nodes :: Array Dagre.NodeOptions
  , edges :: Array { source :: String, target :: String }
  , rankDir :: Dagre.RankDir
  , positions :: Maybe (Map String Position)
  , dims :: Maybe { width :: Number, height :: Number }
  , newNodeId :: String
  , newNodeLabel :: String
  , newEdgeSource :: String
  , newEdgeTarget :: String
  }

initialState :: State
initialState =
  { nodes:
      [ { id: "source", width: 120.0, height: 50.0, label: "source" }
      , { id: "compile", width: 120.0, height: 50.0, label: "compile" }
      , { id: "link", width: 120.0, height: 50.0, label: "link" }
      , { id: "test", width: 120.0, height: 50.0, label: "test" }
      , { id: "package", width: 120.0, height: 50.0, label: "package" }
      ]
  , edges:
      [ { source: "source", target: "compile" }
      , { source: "compile", target: "link" }
      , { source: "link", target: "test" }
      , { source: "test", target: "package" }
      ]
  , rankDir: Dagre.TopBottom
  , positions: Nothing
  , dims: Nothing
  , newNodeId: ""
  , newNodeLabel: ""
  , newEdgeSource: ""
  , newEdgeTarget: ""
  }

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI component unit body

component :: forall q i o m. MonadEffect m => H.Component q i o m
component = Hooks.component \_ _ -> Hooks.do
  Tuple st stId <- Hooks.useState initialState

  Hooks.useLifecycleEffect do
    s <- Hooks.get stId
    result <- liftEffect $ buildAndLayout s.nodes s.edges s.rankDir
    Hooks.put stId s { positions = Just result.positions, dims = result.dims }
    pure Nothing

  let
    relayout nodes edges dir = do
      result <- liftEffect $ buildAndLayout nodes edges dir
      Hooks.modify_ stId \s -> s
        { nodes = nodes
        , edges = edges
        , rankDir = dir
        , positions = Just result.positions
        , dims = result.dims
        }

    onRankDirChange v = do
      s <- Hooks.get stId
      let dir = case v of
            "TB" -> Dagre.TopBottom
            "BT" -> Dagre.BottomTop
            "LR" -> Dagre.LeftRight
            _ -> Dagre.RightLeft
      relayout s.nodes s.edges dir

    onAddNode = do
      s <- Hooks.get stId
      if s.newNodeId == "" then pure unit
      else do
        let node = { id: s.newNodeId, width: 120.0, height: 50.0, label: if s.newNodeLabel == "" then s.newNodeId else s.newNodeLabel }
        relayout (s.nodes <> [ node ]) s.edges s.rankDir
        Hooks.modify_ stId \st' -> st' { newNodeId = "", newNodeLabel = "" }

    onRemoveNode id = do
      s <- Hooks.get stId
      let nodes = filter (\n -> n.id /= id) s.nodes
          edges = filter (\e -> e.source /= id && e.target /= id) s.edges
      relayout nodes edges s.rankDir

    onAddEdge = do
      s <- Hooks.get stId
      if s.newEdgeSource == "" || s.newEdgeTarget == "" then pure unit
      else do
        relayout s.nodes (s.edges <> [ { source: s.newEdgeSource, target: s.newEdgeTarget } ]) s.rankDir
        Hooks.modify_ stId \st' -> st' { newEdgeSource = "", newEdgeTarget = "" }

    onRemoveEdge src tgt = do
      s <- Hooks.get stId
      let edges = filter (\e -> not (e.source == src && e.target == tgt)) s.edges
      relayout s.nodes edges s.rankDir

  Hooks.pure $
    HH.div [ HP.class_ (HH.ClassName "app") ]
      [ HH.div [ HP.class_ (HH.ClassName "header") ]
          [ HH.h1_ [ HH.text "dagre-demo" ]
          , HH.p_ [ HH.text "Interactive graph layout — add/remove nodes and edges, change direction." ]
          ]
      , HH.div [ HP.class_ (HH.ClassName "layout") ]
          [ HH.div [ HP.class_ (HH.ClassName "controls") ]
              [ HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text "Rank Direction" ]
                  , HH.select
                      [ HE.onValueChange onRankDirChange
                      , HP.value (rankDirString st.rankDir)
                      ]
                      [ HH.option [ HP.value "TB" ] [ HH.text "Top \x2192 Bottom" ]
                      , HH.option [ HP.value "BT" ] [ HH.text "Bottom \x2192 Top" ]
                      , HH.option [ HP.value "LR" ] [ HH.text "Left \x2192 Right" ]
                      , HH.option [ HP.value "RL" ] [ HH.text "Right \x2192 Left" ]
                      ]
                  ]
              , HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text "Add Node" ]
                  , HH.div [ HP.class_ (HH.ClassName "inline-form") ]
                      [ HH.input
                          [ HP.type_ HP.InputText
                          , HP.placeholder "id"
                          , HP.value st.newNodeId
                          , HE.onValueInput \v -> Hooks.modify_ stId \s -> s { newNodeId = v }
                          ]
                      , HH.input
                          [ HP.type_ HP.InputText
                          , HP.placeholder "label (optional)"
                          , HP.value st.newNodeLabel
                          , HE.onValueInput \v -> Hooks.modify_ stId \s -> s { newNodeLabel = v }
                          ]
                      , HH.button
                          [ HE.onClick \_ -> onAddNode
                          , HP.class_ (HH.ClassName "btn")
                          ]
                          [ HH.text "+ Add" ]
                      ]
                  ]
              , HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text "Add Edge" ]
                  , HH.div [ HP.class_ (HH.ClassName "inline-form") ]
                      [ nodeSelect "source" st.newEdgeSource (\v -> Hooks.modify_ stId \s -> s { newEdgeSource = v }) st.nodes
                      , HH.span_ [ HH.text "\x2192" ]
                      , nodeSelect "target" st.newEdgeTarget (\v -> Hooks.modify_ stId \s -> s { newEdgeTarget = v }) st.nodes
                      , HH.button
                          [ HE.onClick \_ -> onAddEdge
                          , HP.class_ (HH.ClassName "btn")
                          ]
                          [ HH.text "+ Add" ]
                      ]
                  ]
              , HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text ("Nodes (" <> show (length st.nodes) <> ") \x2014 click to remove") ]
                  , HH.div [ HP.class_ (HH.ClassName "chip-list") ]
                      (map (\n ->
                        HH.span
                          [ HP.class_ (HH.ClassName "chip node-chip")
                          , HE.onClick \_ -> onRemoveNode n.id
                          ]
                          [ HH.text n.label ]) st.nodes)
                  ]
              , HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text ("Edges (" <> show (length st.edges) <> ") \x2014 click to remove") ]
                  , HH.div [ HP.class_ (HH.ClassName "chip-list") ]
                      (map (\e ->
                        HH.span
                          [ HP.class_ (HH.ClassName "chip edge-chip")
                          , HE.onClick \_ -> onRemoveEdge e.source e.target
                          ]
                          [ HH.text (e.source <> " \x2192 " <> e.target) ]) st.edges)
                  ]
              ]
          , HH.div [ HP.class_ (HH.ClassName "canvas") ]
              [ case st.positions of
                  Nothing -> HH.p_ [ HH.text "Computing layout..." ]
                  Just pm -> renderSvg pm st.dims st.edges
              ]
          ]
      ]
  where
  nodeSelect ph val onInput nodes =
    HH.select
      [ HE.onValueChange onInput
      , HP.value val
      ]
      (HH.option [ HP.value "" ] [ HH.text ph ] : map (\n -> HH.option [ HP.value n.id ] [ HH.text n.id ]) nodes)

rankDirString :: Dagre.RankDir -> String
rankDirString = case _ of
  Dagre.TopBottom -> "TB"
  Dagre.BottomTop -> "BT"
  Dagre.LeftRight -> "LR"
  Dagre.RightLeft -> "RL"

-- | Build a dagre graph from the given nodes/edges, run layout, return positions + dimensions.
buildAndLayout
  :: Array Dagre.NodeOptions
  -> Array { source :: String, target :: String }
  -> Dagre.RankDir
  -> Effect { positions :: Map String Position, dims :: Maybe { width :: Number, height :: Number } }
buildAndLayout nodes edges dir = do
  g <- Dagre.new
  Dagre.setRankDir dir g
  traverse_ (\n -> Dagre.setNode n g) nodes
  traverse_ (\e -> Dagre.setEdge e g) edges
  Dagre.layout g
  ids <- Dagre.nodeIds g
  entries <- traverse (\id -> Tuple id <$> fromMaybePos id g) ids
  dims <- Dagre.dimensions g
  pure { positions: Map.fromFoldable entries, dims }

fromMaybePos :: String -> Dagre.Graph -> Effect Position
fromMaybePos id g = do
  mp <- Dagre.nodePosition id g
  pure case mp of
    Just p -> p
    Nothing -> { x: 0.0, y: 0.0 }

-- SVG rendering

svgNS :: H.Namespace
svgNS = H.Namespace "http://www.w3.org/2000/svg"

svgEl :: forall r i w. String -> Array (HH.IProp r i) -> Array (HH.HTML w i) -> HH.HTML w i
svgEl name = HH.elementNS svgNS (H.ElemName name)

svgAttr :: forall r i. String -> String -> HH.IProp r i
svgAttr k = HH.attr (HH.AttrName k)

renderSvg
  :: forall w i
   . Map String Position
  -> Maybe { width :: Number, height :: Number }
  -> Array { source :: String, target :: String }
  -> HH.HTML w i
renderSvg pm mdims edges =
  let
    w = show (fromMaybe 400.0 (_.width <$> mdims) + 80.0)
    h = show (fromMaybe 350.0 (_.height <$> mdims) + 80.0)
  in
    svgEl "svg"
      [ svgAttr "width" w
      , svgAttr "height" h
      , svgAttr "viewBox" ("0 0 " <> w <> " " <> h)
      ]
      [ svgEl "defs" []
          [ svgEl "marker"
              [ svgAttr "id" "arrowhead"
              , svgAttr "markerWidth" "10"
              , svgAttr "markerHeight" "7"
              , svgAttr "refX" "9"
              , svgAttr "refY" "3.5"
              , svgAttr "orient" "auto"
              ]
              [ svgEl "polygon" [ svgAttr "points" "0 0, 10 3.5, 0 7", svgAttr "fill" "#999" ] []
              ]
          ]
      , svgEl "g" []
          (map (renderEdge pm) edges <> map renderNode (Map.toUnfoldable pm))
      ]

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
        , svgAttr "stroke-width" "2"
        ]
        []
    , svgEl "text"
        [ svgAttr "x" (show x)
        , svgAttr "y" (show (y + 5.0))
        , svgAttr "text-anchor" "middle"
        , svgAttr "font-family" "sans-serif"
        , svgAttr "font-size" "14"
        , svgAttr "fill" "#333"
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
        , svgAttr "marker-end" "url(#arrowhead)"
        ]
        []
    _, _ -> HH.text ""
