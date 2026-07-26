-- | viz.js interop helpers.
-- |
-- | `setInnerHTMLById` injects a raw SVG string (from viz.js) into a DOM
-- | element by id. Halogen has no built-in way to set `innerHTML`, so we go
-- | through a small FFI.
-- |
-- | `extractSvg` strips the XML declaration, DOCTYPE, and comments that
-- | `@viz-js/viz` emits before the `<svg>` element so only the SVG markup
-- | remains — required for direct `innerHTML` injection.
module Example.Viz
  ( extractSvg
  , setInnerHTMLById
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), drop, indexOf)
import Effect (Effect)

-- | Inject raw HTML into a DOM element by id. Used for viz.js SVG output.
foreign import setInnerHTMLById :: String -> String -> Effect Unit

-- | Extract just the `<svg>...</svg>` element from viz.js output.
extractSvg :: String -> String
extractSvg s = case indexOf (Pattern "<svg") s of
  Just i -> drop i s
  Nothing -> s
