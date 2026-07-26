module Test.Main where

import Prelude

import Data.Either (Either(..), isLeft, isRight)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner (run)
import Viz (new)
import Viz.Render (Engine(..), RenderOptions, renderJSON, renderString)

main :: Effect Unit
main = launchAff_ $ run [ consoleReporter ] do
  viz <- new

  describe "Viz.Render" do
    it "renders a simple DOT digraph to SVG" do
      let result = renderString viz "digraph { a -> b }" Nothing
      result `shouldSatisfy` isRight
      case result of
        Right svg -> svg `shouldSatisfy` contains (Pattern "<svg")
        Left _ -> pure unit

    it "renders SVG with explicit options" do
      let opts :: RenderOptions; opts = { format: "svg", engine: Dot }
      let result = renderString viz "digraph { a -> b }" (Just opts)
      result `shouldSatisfy` isRight

    it "renders JSON output" do
      let result = renderJSON viz "digraph { a -> b }" Nothing
      result `shouldSatisfy` isRight

    it "returns errors for invalid DOT" do
      let result = renderString viz "this is not valid DOT" Nothing
      result `shouldSatisfy` isLeft

    it "supports different engines (neato)" do
      let opts :: RenderOptions; opts = { format: "svg", engine: Neato }
      let result = renderString viz "digraph { a -> b }" (Just opts)
      result `shouldSatisfy` isRight
