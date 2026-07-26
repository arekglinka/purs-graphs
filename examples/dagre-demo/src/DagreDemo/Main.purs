-- | dagre-demo: an interactive graph layout playground using purs-dagre.
-- |
-- | Users can add/remove nodes and edges, change rank direction, and see the
-- | layout update live. SVG auto-sizes to the computed graph dimensions.
module DagreDemo.Main where

import Prelude

import Dagre.Graph (NodeOptions, RankDir(..), rankDirToString) as Dagre
import Data.Array (filter, length, (:))
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Example.DagreRun (Position, buildAndLayout)
import Example.Svg (arrowheadDefs, cn, svgAttr, svgEl)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)

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

inputCls :: String
inputCls =
  "px-2 py-1.5 border border-gray-300 rounded text-sm bg-white focus:outline-none focus:border-brand"

inputSmCls :: String
inputSmCls = inputCls <> " w-[90px]"

btnCls :: String
btnCls =
  "px-3 py-1.5 bg-brand text-white border-0 rounded cursor-pointer text-sm whitespace-nowrap hover:bg-brand-dark"

labelCls :: String
labelCls = "text-xs font-semibold uppercase tracking-wide text-gray-600"

chipBase :: String
chipBase =
  "inline-block px-2 py-0.5 rounded-full text-xs cursor-pointer select-none transition-opacity hover:opacity-60"

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
      let
        dir = case v of
          "TB" -> Dagre.TopBottom
          "BT" -> Dagre.BottomTop
          "LR" -> Dagre.LeftRight
          _ -> Dagre.RightLeft
      relayout s.nodes s.edges dir

    onAddNode = do
      s <- Hooks.get stId
      if s.newNodeId == "" then pure unit
      else do
        let
          node =
            { id: s.newNodeId
            , width: 120.0
            , height: 50.0
            , label: if s.newNodeLabel == "" then s.newNodeId else s.newNodeLabel
            }
        relayout (s.nodes <> [ node ]) s.edges s.rankDir
        Hooks.modify_ stId \st' -> st' { newNodeId = "", newNodeLabel = "" }

    onRemoveNode id = do
      s <- Hooks.get stId
      let
        nodes = filter (\n -> n.id /= id) s.nodes
        edges = filter (\e -> e.source /= id && e.target /= id) s.edges
      relayout nodes edges s.rankDir

    onAddEdge = do
      s <- Hooks.get stId
      if s.newEdgeSource == "" || s.newEdgeTarget == "" then pure unit
      else do
        relayout s.nodes (s.edges <> [ { source: s.newEdgeSource, target: s.newEdgeTarget } ])
          s.rankDir
        Hooks.modify_ stId \st' -> st' { newEdgeSource = "", newEdgeTarget = "" }

    onRemoveEdge src tgt = do
      s <- Hooks.get stId
      let edges = filter (\e -> not (e.source == src && e.target == tgt)) s.edges
      relayout s.nodes edges s.rankDir

  Hooks.pure $
    HH.div_
      [ HH.div [ HP.class_ (cn "mb-6") ]
          [ HH.h1 [ HP.class_ (cn "text-2xl font-bold text-brand m-0") ] [ HH.text "dagre-demo" ]
          , HH.p [ HP.class_ (cn "text-sm text-gray-600 m-0 mt-1") ]
              [ HH.text
                  "Interactive graph layout \x2014 add/remove nodes and edges, change direction."
              ]
          ]
      , HH.div [ HP.class_ (cn "flex gap-6 items-start flex-wrap") ]
          [ HH.div [ HP.class_ (cn "w-[320px] flex flex-col gap-4") ]
              [ HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label [ HP.class_ (cn labelCls) ] [ HH.text "Rank Direction" ]
                  , HH.select
                      [ HE.onValueChange onRankDirChange
                      , HP.value (Dagre.rankDirToString st.rankDir)
                      , HP.class_ (cn inputCls)
                      ]
                      [ HH.option [ HP.value "TB" ] [ HH.text "Top \x2192 Bottom" ]
                      , HH.option [ HP.value "BT" ] [ HH.text "Bottom \x2192 Top" ]
                      , HH.option [ HP.value "LR" ] [ HH.text "Left \x2192 Right" ]
                      , HH.option [ HP.value "RL" ] [ HH.text "Right \x2192 Left" ]
                      ]
                  ]
              , HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label [ HP.class_ (cn labelCls) ] [ HH.text "Add Node" ]
                  , HH.div [ HP.class_ (cn "flex gap-1.5 items-center") ]
                      [ HH.input
                          [ HP.type_ HP.InputText
                          , HP.placeholder "id"
                          , HP.value st.newNodeId
                          , HE.onValueInput \v -> Hooks.modify_ stId \s -> s { newNodeId = v }
                          , HP.class_ (cn inputSmCls)
                          ]
                      , HH.input
                          [ HP.type_ HP.InputText
                          , HP.placeholder "label (optional)"
                          , HP.value st.newNodeLabel
                          , HE.onValueInput \v -> Hooks.modify_ stId \s -> s { newNodeLabel = v }
                          , HP.class_ (cn inputSmCls)
                          ]
                      , HH.button
                          [ HE.onClick \_ -> onAddNode
                          , HP.class_ (cn btnCls)
                          ]
                          [ HH.text "+ Add" ]
                      ]
                  ]
              , HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label [ HP.class_ (cn labelCls) ] [ HH.text "Add Edge" ]
                  , HH.div [ HP.class_ (cn "flex gap-1.5 items-center") ]
                      [ nodeSelect "source" st.newEdgeSource
                          (\v -> Hooks.modify_ stId \s -> s { newEdgeSource = v })
                          st.nodes
                      , HH.span_ [ HH.text "\x2192" ]
                      , nodeSelect "target" st.newEdgeTarget
                          (\v -> Hooks.modify_ stId \s -> s { newEdgeTarget = v })
                          st.nodes
                      , HH.button
                          [ HE.onClick \_ -> onAddEdge
                          , HP.class_ (cn btnCls)
                          ]
                          [ HH.text "+ Add" ]
                      ]
                  ]
              , HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label [ HP.class_ (cn labelCls) ]
                      [ HH.text ("Nodes (" <> show (length st.nodes) <> ") \x2014 click to remove")
                      ]
                  , HH.div [ HP.class_ (cn "flex flex-wrap gap-1.5") ]
                      ( map
                          ( \n ->
                              HH.span
                                [ HP.class_
                                    ( cn
                                        ( chipBase <>
                                            " bg-chip-node-bg text-chip-node-text border border-chip-node-border"
                                        )
                                    )
                                , HE.onClick \_ -> onRemoveNode n.id
                                ]
                                [ HH.text n.label ]
                          )
                          st.nodes
                      )
                  ]
              , HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label [ HP.class_ (cn labelCls) ]
                      [ HH.text ("Edges (" <> show (length st.edges) <> ") \x2014 click to remove")
                      ]
                  , HH.div [ HP.class_ (cn "flex flex-wrap gap-1.5") ]
                      ( map
                          ( \e ->
                              HH.span
                                [ HP.class_
                                    ( cn
                                        ( chipBase <>
                                            " bg-chip-edge-bg text-chip-edge-text border border-chip-edge-border"
                                        )
                                    )
                                , HE.onClick \_ -> onRemoveEdge e.source e.target
                                ]
                                [ HH.text (e.source <> " \x2192 " <> e.target) ]
                          )
                          st.edges
                      )
                  ]
              ]
          , HH.div [ HP.class_ (cn "flex-1 min-w-[300px] canvas-area") ]
              [ case st.positions of
                  Nothing -> HH.p_ [ HH.text "Computing layout..." ]
                  Just pm -> renderSvg pm st.dims st.nodes st.edges
              ]
          ]
      ]
  where
  nodeSelect ph val onInput nodes =
    HH.select
      [ HE.onValueChange onInput
      , HP.value val
      , HP.class_ (cn inputSmCls)
      ]
      ( HH.option [ HP.value "" ] [ HH.text ph ] : map
          (\n -> HH.option [ HP.value n.id ] [ HH.text n.id ])
          nodes
      )

renderSvg
  :: forall w i
   . Map String Position
  -> Maybe { width :: Number, height :: Number }
  -> Array Dagre.NodeOptions
  -> Array { source :: String, target :: String }
  -> HH.HTML w i
renderSvg pm mdims nodes edges =
  let
    w = show (fromMaybe 400.0 (_.width <$> mdims) + 80.0)
    h = show (fromMaybe 350.0 (_.height <$> mdims) + 80.0)
  in
    svgEl "svg"
      [ svgAttr "width" w
      , svgAttr "height" h
      , svgAttr "viewBox" ("0 0 " <> w <> " " <> h)
      ]
      [ arrowheadDefs
      , svgEl "g" []
          (map (renderEdge pm) edges <> map (renderNode pm) nodes)
      ]

renderNode :: forall w i. Map String Position -> Dagre.NodeOptions -> HH.HTML w i
renderNode pm node =
  case Map.lookup node.id pm of
    Nothing -> HH.text ""
    Just { x, y } ->
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
            [ HH.text node.label ]
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
