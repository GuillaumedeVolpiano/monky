{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE EmptyDataDecls #-}
{-|
Module      : Monky.Outputs.Ascii
Description : Output module for Ascii
Maintainer  : ongy
Stability   : testing
Portability : Linux

This module provides the output generation for ascii outputs
-}
module Monky.Outputs.Ascii
  ( AsciiOutput
  , getAsciiOut
  )
where

import System.IO (hFlush, stdout)
import Monky.Modules

import qualified Data.Text.IO as T

-- |The output handle for a ascii pipe
data AsciiOutput = AsciiOutput

doOut :: MonkyOut -> IO ()
doOut (MonkyPlain t)   = T.putStr t
doOut (MonkyImage _ _) = return () -- Images are not supported :(
doOut (MonkyBar p)     = putStr (show p) >> putChar '%'
doOut (MonkyHBar p)    = putStr $ show p
doOut (MonkyColor _ o) = doOut o

doSegment :: [MonkyOut] -> IO ()
doSegment = mapM_ doOut

instance MonkyOutput AsciiOutput where
  doLine _ [] = error "Why are you calling doLine without any modules? I don't think your config makes sense"
  doLine _ [x] = do
    doSegment x
    putStr "\n"
    hFlush stdout
  doLine h (x:xs) = do
    doSegment x
    putStr " | "
    doLine h xs

-- |Get an output handle for ascii formatting
getAsciiOut :: IO AsciiOutput
getAsciiOut = return AsciiOutput
