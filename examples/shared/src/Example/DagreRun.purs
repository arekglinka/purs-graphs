-- | Dagre layout runner — builds a graph, runs layout, returns positions.
-- |
-- | Used by example apps that need to take PureScript node/edge data, compute
-- | layout via purs-dagre, and render the result. The library package itself
-- | only exposes the building blocks (`new`, `setNode`, `setEdge`, `layout`,
-- | etc.); this module combines them into a single convenient call.
module Example.DagreRun
  ( Position
  , buildAndLayout
  ) where

import Prelude

import Dagre.Graph (Graph, NodeOptions, RankDir)
import Dagre.Graph as Dagre
import Data.Foldable (traverse_)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..))
import Effect (Effect)

-- | A 2D position computed by the dagre layout algorithm.
-- | (Structurally identical to `Dagre.Graph.Position`; not re-exported because
-- | PureScript can't selectively re-export imported types.)
type Position =
  { x :: Number
  , y :: Number
  }

-- | Build a dagre graph from the given nodes/edges, run layout, and return
-- | the computed positions keyed by node id, plus the total graph dimensions.
buildAndLayout
  :: Array NodeOptions
  -> Array { source :: String, target :: String }
  -> RankDir
  -> Effect
       { positions :: Map String Position, dims :: Maybe { width :: Number, height :: Number } }
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

fromMaybePos :: String -> Graph -> Effect Position
fromMaybePos id g = do
  mp <- Dagre.nodePosition id g
  pure case mp of
    Just p -> p
    Nothing -> { x: 0.0, y: 0.0 }
