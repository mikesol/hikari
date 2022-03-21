module Main where

import Prelude

import BMS.Parser (bms)
import BMS.Timing (gatherAll, noteOffsets)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import FRP.Event (subscribe)
import FRP.Event.Time (interval)
import Hikari.Engine (scene)
import Hikari.Fetch (fetchText)
import Hikari.Residuals (Residuals)
import Hikari.World (loadKeySoundBuffers)
import WAGS.Interpret (context, makeFFIAudioSnapshot)
import WAGS.Run (TriggeredRun, runNoLoop)

main :: Effect Unit
main = launchAff_ do
  audioCtx <- liftEffect context
  ffiAudio <- liftEffect $ makeFFIAudioSnapshot audioCtx

  bme <- gatherAll <<< bms <$> fetchText "./sounds/01.bme"
  let noteWithOffsets = noteOffsets bme
  keySoundBuffers <- loadKeySoundBuffers audioCtx bme

  let
    timeEvent = interval 1000 $> unit
    world = { keySoundBuffers, noteWithOffsets }

  _ <- liftEffect $ subscribe (runNoLoop timeEvent (pure world) {} ffiAudio scene)
    (\(_ :: TriggeredRun Residuals ()) -> pure unit)

  pure unit
