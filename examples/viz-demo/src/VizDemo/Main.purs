-- | viz-demo: an interactive DOT playground using viz.js.
-- |
-- | Users can edit DOT source, switch layout engines, and see the SVG
-- | re-render live.
module VizDemo.Main where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), indexOf, drop, joinWith)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff.Class (class MonadAff, liftAff)
import Effect.Class (liftEffect)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.Hooks as Hooks
import Halogen.VDom.Driver (runUI)
import Viz (VizInstance, new)
import Viz.Render (Engine(..), engineToString, renderString)

-- | Inject raw HTML into a DOM element by ID (used for SVG from viz.js).
foreign import setInnerHTMLById :: String -> String -> Effect Unit

-- | Extract just the <svg>...</svg> element from viz.js output (strips XML
-- | declaration, DOCTYPE, and comments).
extractSvg :: String -> String
extractSvg s =
  case indexOf (Pattern "<svg") s of
    Just i -> drop i s
    Nothing -> s

-- | The initial DOT source shown in the editor.
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

  -- Create viz instance once, then do initial render
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
      Hooks.put stId { dot, engine, svgOutput: Just result, vizInstance: Just viz }
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
      let engine = case v of
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
    HH.div [ HP.class_ (HH.ClassName "app") ]
      [ HH.div [ HP.class_ (HH.ClassName "header") ]
          [ HH.h1_ [ HH.text "viz-demo" ]
          , HH.p_ [ HH.text "Edit DOT source, switch engines, re-render live." ]
          ]
      , HH.div [ HP.class_ (HH.ClassName "layout") ]
          [ HH.div [ HP.class_ (HH.ClassName "controls") ]
              [ HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text "DOT Source" ]
                  , HH.textarea
                      [ HP.value st.dot
                      , HE.onValueInput onDotChange
                      , HP.class_ (HH.ClassName "dot-editor")
                      , HP.rows 8
                      , HP.spellcheck false
                      ]
                  ]
              , HH.div [ HP.class_ (HH.ClassName "control-group") ]
                  [ HH.label_ [ HH.text "Layout Engine" ]
                  , HH.select
                      [ HE.onValueChange onEngineChange
                      , HP.value (engineToString st.engine)
                      ]
                      [ HH.option [ HP.value "dot" ] [ HH.text "dot (hierarchical)" ]
                      , HH.option [ HP.value "neato" ] [ HH.text "neato (spring)" ]
                      , HH.option [ HP.value "fdp" ] [ HH.text "fdp (force-directed)" ]
                      , HH.option [ HP.value "circo" ] [ HH.text "circo (circular)" ]
                      , HH.option [ HP.value "twopi" ] [ HH.text "twopi (radial)" ]
                      ]
                  , HH.button
                      [ HE.onClick \_ -> onRender
                      , HP.class_ (HH.ClassName "btn")
                      ]
                      [ HH.text "Render" ]
                  ]
              ]
          , HH.div [ HP.class_ (HH.ClassName "canvas") ]
              [ HH.h3_ [ HH.text "Rendered SVG" ]
              , HH.div [ HP.id "svg-container", HP.class_ (HH.ClassName "svg-container") ] []
              , case st.svgOutput of
                  Just (Left errs) ->
                    HH.pre [ HP.class_ (HH.ClassName "error-box") ]
                      [ HH.code_ [ HH.text (joinWith "\n" errs) ] ]
                  _ -> HH.text ""
              ]
          ]
      ]
