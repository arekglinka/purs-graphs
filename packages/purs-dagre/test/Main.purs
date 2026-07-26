module Test.Main where

import Prelude

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
  ) as Graph
import Data.Maybe (Maybe(..), isJust)
import Data.Traversable (traverse_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (run)

nodes :: Array Graph.NodeOptions
nodes =
  [ { id: "source", width: 100.0, height: 40.0, label: "source" }
  , { id: "compile", width: 100.0, height: 40.0, label: "compile" }
  , { id: "link", width: 100.0, height: 40.0, label: "link" }
  , { id: "test", width: 100.0, height: 40.0, label: "test" }
  , { id: "package", width: 100.0, height: 40.0, label: "package" }
  ]

edges :: Array { source :: String, target :: String }
edges =
  [ { source: "source", target: "compile" }
  , { source: "compile", target: "link" }
  , { source: "link", target: "test" }
  , { source: "test", target: "package" }
  ]

buildGraph :: Effect Graph.Graph
buildGraph = do
  g <- Graph.new
  Graph.setRankDir Graph.TopBottom g
  traverse_ (\n -> Graph.setNode n g) nodes
  traverse_ (\e -> Graph.setEdge e g) edges
  pure g

main :: Effect Unit
main = run [ consoleReporter ] do
  describe "Dagre.Graph" do
    it "creates a graph and lists all node ids" do
      g <- liftEffect buildGraph
      ids <- liftEffect $ Graph.nodeIds g
      ids `shouldEqual` map _.id nodes

    it "computes positions for all nodes after layout" do
      g <- liftEffect buildGraph
      liftEffect $ Graph.layout g
      pos <- liftEffect $ Graph.nodePosition "compile" g
      pos `shouldSatisfy` isJust

    it "returns Nothing for a non-existent node" do
      g <- liftEffect buildGraph
      liftEffect $ Graph.layout g
      pos <- liftEffect $ Graph.nodePosition "nonexistent" g
      pos `shouldEqual` Nothing

    it "computes graph dimensions after layout" do
      g <- liftEffect buildGraph
      liftEffect $ Graph.layout g
      dims <- liftEffect $ Graph.dimensions g
      dims `shouldSatisfy` isJust

    it "assigns the first node a y-coordinate at or near the top rank" do
      g <- liftEffect buildGraph
      liftEffect $ Graph.layout g
      srcPos <- liftEffect $ Graph.nodePosition "source" g
      pkgPos <- liftEffect $ Graph.nodePosition "package" g
      case srcPos, pkgPos of
        Just s, Just p -> s.y `shouldSatisfy` (_ <= p.y)
        _, _ -> pure unit
