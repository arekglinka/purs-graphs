-- | viz-demo: an interactive DOT playground using viz.js.
-- |
-- | Users can edit DOT source, switch layout engines, and see the SVG
-- | re-render live.
module VizDemo.Main where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String (joinWith)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Example.Svg (cn)
import Example.Viz (extractSvg, setInnerHTMLById)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)
import Viz (VizInstance, new)
import Viz.Render (Engine(..), engineToString, renderString)

initialDot :: String
initialDot =
  "digraph pipeline {\n"
    <> "  rankdir=TB;\n"
    <> "  node [shape=box, style=rounded, fontname=\"sans-serif\"];\n"
    <> "  source -> compile -> link -> test -> package;\n"
    <> "}\n"

type State =
  { dot :: String
  , engine :: Engine
  , svgOutput :: Maybe (Either (Array String) String)
  , vizInstance :: Maybe VizInstance
  }

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI component unit body

component :: forall q i o m. MonadAff m => H.Component q i o m
component = Hooks.component \_ _ -> Hooks.do
  Tuple st stId <- Hooks.useState
    { dot: initialDot
    , engine: Dot
    , svgOutput: Nothing
    , vizInstance: Nothing
    }

  Hooks.useLifecycleEffect do
    viz <- liftAff new
    let result = renderString viz initialDot (Just { format: "svg", engine: Dot })
    Hooks.put stId { dot: initialDot, engine: Dot, svgOutput: Just result, vizInstance: Just viz }
    case result of
      Right svg -> liftEffect $ setInnerHTMLById "svg-container" (extractSvg svg)
      Left _ -> pure unit
    pure Nothing

  let
    doRender viz dot engine = do
      let result = renderString viz dot (Just { format: "svg", engine })
      Hooks.modify_ stId \s -> s
        { dot = dot, engine = engine, svgOutput = Just result, vizInstance = Just viz }
      case result of
        Right svg -> liftEffect $ setInnerHTMLById "svg-container" (extractSvg svg)
        Left _ -> pure unit

    onRender = do
      s <- Hooks.get stId
      case s.vizInstance of
        Just viz -> doRender viz s.dot s.engine
        Nothing -> pure unit

    onEngineChange v = do
      s <- Hooks.get stId
      let
        engine = case v of
          "neato" -> Neato
          "fdp" -> Fdp
          "circo" -> Circo
          "twopi" -> Twopi
          _ -> Dot
      case s.vizInstance of
        Just viz -> doRender viz s.dot engine
        Nothing -> pure unit

    onDotChange v =
      Hooks.modify_ stId \s -> s { dot = v }

  Hooks.pure $
    HH.div_
      [ HH.div [ HP.class_ (cn "mb-6") ]
          [ HH.h1 [ HP.class_ (cn "text-2xl font-bold text-brand m-0") ] [ HH.text "viz-demo" ]
          , HH.p [ HP.class_ (cn "text-sm text-gray-600 m-0 mt-1") ]
              [ HH.text "Edit DOT source, switch engines, re-render live." ]
          ]
      , HH.div [ HP.class_ (cn "flex gap-6 items-start flex-wrap") ]
          [ HH.div [ HP.class_ (cn "w-[400px] flex flex-col gap-4") ]
              [ HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label
                      [ HP.class_ (cn "text-xs font-semibold uppercase tracking-wide text-gray-600")
                      ]
                      [ HH.text "DOT Source" ]
                  , HH.textarea
                      [ HP.value st.dot
                      , HE.onValueInput onDotChange
                      , HP.class_
                          ( cn
                              "w-full min-h-[160px] p-2 font-mono text-sm leading-relaxed resize-y tab-2 bg-gray-100 border border-gray-300 rounded focus:outline-none focus:border-brand focus:bg-white"
                          )
                      , HP.rows 8
                      , HP.spellcheck false
                      ]
                  ]
              , HH.div [ HP.class_ (cn "flex flex-col gap-1.5") ]
                  [ HH.label
                      [ HP.class_ (cn "text-xs font-semibold uppercase tracking-wide text-gray-600")
                      ]
                      [ HH.text "Layout Engine" ]
                  , HH.select
                      [ HE.onValueChange onEngineChange
                      , HP.value (engineToString st.engine)
                      , HP.class_
                          ( cn
                              "px-2 py-1.5 border border-gray-300 rounded text-sm bg-white focus:outline-none focus:border-brand"
                          )
                      ]
                      [ HH.option [ HP.value "dot" ] [ HH.text "dot (hierarchical)" ]
                      , HH.option [ HP.value "neato" ] [ HH.text "neato (spring)" ]
                      , HH.option [ HP.value "fdp" ] [ HH.text "fdp (force-directed)" ]
                      , HH.option [ HP.value "circo" ] [ HH.text "circo (circular)" ]
                      , HH.option [ HP.value "twopi" ] [ HH.text "twopi (radial)" ]
                      ]
                  , HH.button
                      [ HE.onClick \_ -> onRender
                      , HP.class_
                          ( cn
                              "px-3 py-1.5 bg-brand text-white border-0 rounded cursor-pointer text-sm whitespace-nowrap hover:bg-brand-dark"
                          )
                      ]
                      [ HH.text "Render" ]
                  ]
              ]
          , HH.div [ HP.class_ (cn "flex-1 min-w-[300px]") ]
              [ HH.h3 [ HP.class_ (cn "text-base font-medium text-gray-700 m-0 mb-2") ]
                  [ HH.text "Rendered SVG" ]
              , HH.div
                  [ HP.id "svg-container"
                  , HP.class_
                      ( cn
                          "border border-gray-300 rounded p-4 overflow-x-auto bg-white min-h-[200px]"
                      )
                  ]
                  []
              , case st.svgOutput of
                  Just (Left errs) ->
                    HH.pre
                      [ HP.class_
                          ( cn
                              "mt-2 p-3 bg-red-50 text-red-800 border border-red-200 rounded font-mono text-sm whitespace-pre-wrap"
                          )
                      ]
                      [ HH.code_ [ HH.text (joinWith "\n" errs) ] ]
                  _ -> HH.text ""
              ]
          ]
      ]
