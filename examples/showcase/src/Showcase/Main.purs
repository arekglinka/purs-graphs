module Showcase.Main where

import Prelude

import Dagre.Graph as Dagre
import Data.Either (Either(..))
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Example.DagreRun (Position, buildAndLayout)
import Example.Svg (arrowheadDefs, cn, svgAttr, svgEl)
import Example.Viz (extractSvg, setInnerHTMLById)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)
import Showcase.Diagrams
  ( DiagramSpec
  , categories
  , findDiagram
  , findNodeInfo
  )
import Viz (VizInstance, new)
import Viz.Render (Engine(..), renderString)

foreign import getClickedNodeId :: forall event. event -> String

data RenderMode = DagreMode | VizMode

derive instance eqRenderMode :: Eq RenderMode

type State =
  { selectedDiagram :: String
  , renderMode :: RenderMode
  , selectedNode :: Maybe String
  , vizInstance :: Maybe VizInstance
  , positions :: Maybe (Map String Position)
  , dims :: Maybe { width :: Number, height :: Number }
  }

initialState :: State
initialState =
  { selectedDiagram: "scale"
  , renderMode: DagreMode
  , selectedNode: Nothing
  , vizInstance: Nothing
  , positions: Nothing
  , dims: Nothing
  }

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI component unit body

clsWhen :: Boolean -> String -> String -> String
clsWhen cond whenTrue whenFalse = if cond then whenTrue else whenFalse

toggleBtnBase :: String
toggleBtnBase =
  "px-4 py-1.5 bg-transparent text-xs font-semibold text-ink-secondary rounded-md transition-colors cursor-pointer"

toggleBtnActive :: String
toggleBtnActive =
  "px-4 py-1.5 bg-brand text-white rounded-md shadow-[0_1px_3px_rgba(26,115,232,0.3)] text-xs font-semibold cursor-pointer"

sidebarItemBase :: String
sidebarItemBase =
  "flex gap-2 px-4 py-2 text-sm text-sidebar-text cursor-pointer transition-colors border-l-[3px] border-transparent hover:bg-white/5 hover:text-white"

sidebarItemActive :: String
sidebarItemActive =
  "flex gap-2 px-4 py-2 text-sm text-white cursor-pointer transition-colors border-l-[3px] border-sidebar-active bg-blue-500/15"

sidebarNumBase :: String
sidebarNumBase =
  "w-[22px] h-[22px] rounded-md flex items-center justify-center text-xs font-bold bg-white/10"

sidebarNumActive :: String
sidebarNumActive =
  "w-[22px] h-[22px] rounded-md flex items-center justify-center text-xs font-bold bg-sidebar-active text-white"

component :: forall q i o m. MonadAff m => H.Component q i o m
component = Hooks.component \_ _ -> Hooks.do
  Tuple st stId <- Hooks.useState initialState

  Hooks.useLifecycleEffect do
    viz <- liftAff new
    case findDiagram "scale" of
      Nothing -> pure Nothing
      Just diag -> do
        result <- liftEffect $ buildAndLayout diag.dagreNodes diag.dagreEdges diag.dagreRankDir
        let vizResult = renderString viz diag.dotSource (Just { format: "svg", engine: Dot })
        case vizResult of
          Right svg -> liftEffect $ setInnerHTMLById "svg-container" (extractSvg svg)
          Left _ -> pure unit
        Hooks.put stId
          { selectedDiagram: "scale"
          , renderMode: DagreMode
          , selectedNode: Nothing
          , vizInstance: Just viz
          , positions: Just result.positions
          , dims: result.dims
          }
        pure Nothing

  let
    onSelectDiagram diagId = do
      s <- Hooks.get stId
      case findDiagram diagId of
        Nothing -> pure unit
        Just diag -> do
          result <- liftEffect $ buildAndLayout diag.dagreNodes diag.dagreEdges diag.dagreRankDir
          Hooks.modify_ stId \s2 -> s2
            { selectedDiagram = diagId
            , selectedNode = Nothing
            , positions = Just result.positions
            , dims = result.dims
            }
          case s.vizInstance of
            Just viz ->
              case renderString viz diag.dotSource (Just { format: "svg", engine: Dot }) of
                Right svg -> liftEffect $ setInnerHTMLById "svg-container" (extractSvg svg)
                Left _ -> pure unit
            Nothing -> pure unit

    onToggleMode mode = do
      s <- Hooks.get stId
      Hooks.modify_ stId \s2 -> s2 { renderMode = mode, selectedNode = Nothing }
      case mode of
        VizMode -> case s.vizInstance, findDiagram s.selectedDiagram of
          Just viz, Just diag ->
            case renderString viz diag.dotSource (Just { format: "svg", engine: Dot }) of
              Right svg -> liftEffect $ setInnerHTMLById "svg-container" (extractSvg svg)
              Left _ -> pure unit
          _, _ -> pure unit
        DagreMode -> pure unit

    onSelectNode nodeId =
      if nodeId == "" then pure unit
      else Hooks.modify_ stId \s -> s { selectedNode = Just nodeId }

  Hooks.pure $
    case findDiagram st.selectedDiagram of
      Nothing -> HH.text "Diagram not found"
      Just diag ->
        HH.div_
          [ HH.div
              [ HP.class_
                  ( cn
                      "relative z-10 flex justify-between items-center px-6 h-14 bg-surface border-b border-line shadow-[0_1px_3px_rgba(0,0,0,0.08)]"
                  )
              ]
              [ HH.div [ HP.class_ (cn "flex items-center gap-3") ]
                  [ HH.div
                      [ HP.class_
                          ( cn
                              "w-8 h-8 rounded-lg bg-gradient-to-br from-brand to-green flex items-center justify-center text-white font-extrabold text-sm"
                          )
                      ]
                      [ HH.text "BB" ]
                  , HH.div_
                      [ HH.h1 [ HP.class_ (cn "text-lg font-bold text-ink m-0") ]
                          [ HH.text "ByteByteGo System Design Showcase" ]
                      , HH.div [ HP.class_ (cn "text-xs text-ink-secondary mt-px") ]
                          [ HH.text "purs-dagre + purs-viz" ]
                      ]
                  ]
              , HH.div [ HP.class_ (cn "flex bg-canvas-bg rounded-lg p-0.5 border border-line") ]
                  [ HH.button
                      [ HP.class_
                          (cn (clsWhen (st.renderMode == DagreMode) toggleBtnActive toggleBtnBase))
                      , HE.onClick \_ -> onToggleMode DagreMode
                      ]
                      [ HH.text "Dagre" ]
                  , HH.button
                      [ HP.class_
                          (cn (clsWhen (st.renderMode == VizMode) toggleBtnActive toggleBtnBase))
                      , HE.onClick \_ -> onToggleMode VizMode
                      ]
                      [ HH.text "Graphviz" ]
                  ]
              ]
          , HH.div [ HP.class_ (cn "flex h-[calc(100vh-3.5rem)]") ]
              [ renderSidebar st.selectedDiagram onSelectDiagram
              , renderCanvas st diag onSelectNode
              , renderDetailPanel st diag
              ]
          ]

renderSidebar :: forall w i. String -> (String -> i) -> HH.HTML w i
renderSidebar selectedId onSelect =
  HH.div [ HP.class_ (cn "w-60 bg-sidebar-bg overflow-y-auto shrink-0 py-2") ] $
    map
      ( \cat ->
          HH.div_
            $
              [ HH.div
                  [ HP.class_
                      ( cn
                          "px-4 pt-2 pb-1 text-xs font-bold uppercase tracking-wider text-sidebar-muted"
                      )
                  ]
                  [ HH.text cat.name ]
              ]
                <> map (\dId -> renderSidebarItem dId selectedId onSelect) cat.ids
      )
      categories

renderSidebarItem :: forall w i. String -> String -> (String -> i) -> HH.HTML w i
renderSidebarItem dId selectedId onSelect =
  let
    isActive = dId == selectedId
  in
    HH.div
      [ HP.class_ (cn (clsWhen isActive sidebarItemActive sidebarItemBase))
      , HE.onClick \_ -> onSelect dId
      ]
      [ HH.span [ HP.class_ (cn (clsWhen isActive sidebarNumActive sidebarNumBase)) ]
          [ HH.text (showItemNum dId) ]
      , HH.text (showItemTitle dId)
      ]

showItemNum :: String -> String
showItemNum dId = case dId of
  "scale" -> "1"
  "blueprint" -> "2"
  "cache" -> "3"
  "cicd" -> "4"
  "youtube" -> "5"
  "kafka" -> "6"
  "oauth" -> "7"
  "sharding" -> "8"
  _ -> "?"

showItemTitle :: String -> String
showItemTitle dId = case dId of
  "scale" -> "Scale Zero to Millions"
  "blueprint" -> "System Design Blueprint"
  "cache" -> "Cache Layers"
  "cicd" -> "CI/CD Pipeline"
  "youtube" -> "YouTube Architecture"
  "kafka" -> "Kafka Zero-Copy"
  "oauth" -> "OAuth 2.0 Flow"
  "sharding" -> "Database Sharding"
  _ -> dId

renderCanvas :: forall w i. State -> DiagramSpec -> (String -> i) -> HH.HTML w i
renderCanvas st diag onSelect =
  HH.div [ HP.class_ (cn "flex-1 flex flex-col overflow-hidden") ]
    [ HH.div [ HP.class_ (cn "px-6 py-3 bg-surface border-b border-line") ]
        [ HH.h2 [ HP.class_ (cn "text-base font-bold text-ink mb-0.5") ] [ HH.text diag.title ]
        , HH.p [ HP.class_ (cn "text-xs text-ink-secondary leading-relaxed") ]
            [ HH.text diag.description ]
        ]
    , HH.div
        [ HP.class_ (cn "flex-1 overflow-auto p-6 flex items-start justify-center canvas-dots") ]
        [ case st.renderMode of
            DagreMode -> case st.positions of
              Nothing -> HH.p_ [ HH.text "Computing layout..." ]
              Just pm -> renderDagreSvg pm st.dims diag.dagreNodes diag.dagreEdges onSelect
                st.selectedNode
            VizMode -> HH.text ""
        , HH.div
            [ HP.id "svg-container"
            , HP.class_
                ( cn
                    ( clsWhen (st.renderMode == VizMode) "w-full flex justify-center"
                        "w-full hidden"
                    )
                )
            , HE.onClick \ev -> onSelect (getClickedNodeId ev)
            ]
            []
        ]
    ]

renderDetailPanel :: forall w i. State -> DiagramSpec -> HH.HTML w i
renderDetailPanel st diag =
  HH.div [ HP.class_ (cn "w-80 bg-surface border-l border-line overflow-y-auto shrink-0 p-6") ]
    [ HH.h3 [ HP.class_ (cn "text-xs font-bold uppercase tracking-wider text-ink-secondary mb-2") ]
        [ HH.text "Node Details" ]
    , case st.selectedNode of
        Just nodeId -> case findNodeInfo diag nodeId of
          Just info ->
            HH.div [ HP.class_ (cn "p-4 bg-canvas-bg rounded-[10px] mb-4") ]
              [ HH.div [ HP.class_ (cn "text-base font-bold text-ink mb-1") ] [ HH.text info.label ]
              , HH.div [ HP.class_ (cn "text-xs text-ink-secondary font-mono mb-1.5") ]
                  [ HH.text ("ID: " <> info.id) ]
              , HH.div [ HP.class_ (cn "text-sm text-ink-secondary leading-relaxed") ]
                  [ HH.text info.detail ]
              ]
          Nothing ->
            HH.div
              [ HP.class_
                  ( cn
                      "text-sm text-ink-secondary p-4 text-center border border-dashed border-line rounded-lg"
                  )
              ]
              [ HH.text ("No info for: " <> nodeId) ]
        Nothing ->
          HH.div
            [ HP.class_
                ( cn
                    "text-sm text-ink-secondary p-4 text-center border border-dashed border-line rounded-lg"
                )
            ]
            [ HH.text "Click a node to see details" ]
    , HH.h3 [ HP.class_ (cn "text-xs font-bold uppercase tracking-wider text-ink-secondary mb-2") ]
        [ HH.text "Legend" ]
    , HH.div [ HP.class_ (cn "mt-6") ]
        [ legendItem "#bbdefb" "Entry / Input"
        , legendItem "#ffe0b2" "Processing"
        , legendItem "#c8e6c9" "Caching / CDN"
        , legendItem "#f8bbd0" "Distribution"
        , legendItem "#e1bee7" "Advanced"
        ]
    ]
  where
  legendItem color label =
    HH.div [ HP.class_ (cn "flex items-center gap-2 text-xs text-ink-secondary mb-1") ]
      [ HH.span
          [ HP.class_ (cn "w-3.5 h-3.5 rounded border border-line")
          , HP.style ("background:" <> color)
          ]
          []
      , HH.text label
      ]

renderDagreSvg
  :: forall w i
   . Map String Position
  -> Maybe { width :: Number, height :: Number }
  -> Array Dagre.NodeOptions
  -> Array { source :: String, target :: String }
  -> (String -> i)
  -> Maybe String
  -> HH.HTML w i
renderDagreSvg pm mdims nodes edges onSelect selected =
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
          (map (renderDagreEdge pm) edges <> map (renderDagreNode pm onSelect selected) nodes)
      ]

renderDagreNode
  :: forall w i
   . Map String Position
  -> (String -> i)
  -> Maybe String
  -> Dagre.NodeOptions
  -> HH.HTML w i
renderDagreNode pm onSelect selected node =
  case Map.lookup node.id pm of
    Nothing -> HH.text ""
    Just { x, y } ->
      let
        isSel = selected == Just node.id
        fill = if isSel then "#fff3e0" else "#e3f2fd"
        stroke = if isSel then "#e65100" else "#1976d2"
      in
        svgEl "g"
          [ svgAttr "cursor" "pointer"
          , HE.onClick \_ -> onSelect node.id
          ]
          [ svgEl "rect"
              [ svgAttr "x" (show (x - 65.0))
              , svgAttr "y" (show (y - 22.0))
              , svgAttr "width" "130"
              , svgAttr "height" "44"
              , svgAttr "rx" "8"
              , svgAttr "fill" fill
              , svgAttr "stroke" stroke
              , svgAttr "stroke-width" "2"
              ]
              []
          , svgEl "text"
              [ svgAttr "x" (show x)
              , svgAttr "y" (show (y + 5.0))
              , svgAttr "text-anchor" "middle"
              , svgAttr "font-family" "sans-serif"
              , svgAttr "font-size" "13"
              , svgAttr "fill" "#333"
              ]
              [ HH.text node.label ]
          ]

renderDagreEdge
  :: forall w i
   . Map String Position
  -> { source :: String, target :: String }
  -> HH.HTML w i
renderDagreEdge pm { source, target } =
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
