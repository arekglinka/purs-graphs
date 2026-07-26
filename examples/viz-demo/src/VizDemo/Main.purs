-- | viz-demo: a Halogen app that renders the same 5-node build-pipeline graph
-- | using viz.js (DOT → SVG string).
module VizDemo.Main where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String (joinWith)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff, liftAff)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)
import Viz (new)
import Viz.Render (renderString)

-- | The same pipeline graph, expressed as DOT source.
dotSource :: String
dotSource =
  "digraph pipeline {\n"
    <> "  rankdir=TB;\n"
    <> "  node [shape=box, style=rounded, fontname=sans-serif];\n"
    <> "  source -> compile -> link -> test -> package;\n"
    <> "}\n"

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI component unit body

component :: forall q i o m. MonadAff m => H.Component q i o m
component = Hooks.component \_ _ -> Hooks.do
  Tuple svg svgId <- Hooks.useState (Nothing :: Maybe String)
  Tuple error errorId <- Hooks.useState (Nothing :: Maybe String)

  Hooks.useLifecycleEffect do
    viz <- liftAff new
    case renderString viz dotSource Nothing of
      Right s -> Hooks.put svgId (Just s)
      Left errs -> Hooks.put errorId (Just (joinWith "\n" errs))
    pure Nothing

  Hooks.pure $
    HH.div_
      [ HH.h1_ [ HH.text "viz-demo — DOT to SVG via viz.js" ]
      , HH.p_ [ HH.text "The same 5-node build-pipeline graph, rendered by Graphviz." ]
      , HH.h2_ [ HH.text "DOT source" ]
      , HH.pre [ HP.style "background: #f5f5f5; padding: 1rem; overflow-x: auto;" ]
          [ HH.code_ [ HH.text dotSource ] ]
      , HH.h2_ [ HH.text "SVG output" ]
      , case svg of
          Just s ->
            HH.pre [ HP.style "background: #e8f5e9; padding: 1rem; overflow-x: auto; max-height: 500px;" ]
              [ HH.code_ [ HH.text s ] ]
          Nothing -> case error of
            Just e -> HH.pre [ HP.style "color: red;" ] [ HH.text e ]
            Nothing -> HH.p_ [ HH.text "Rendering..." ]
      ]
