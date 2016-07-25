{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE CPP #-}
{-|
Module      : Monky.Outputs.Fallback
Description : Output module for doing a "best guess"
Maintainer  : ongy
Stability   : testing
Portability : Linux

-}
module Monky.Outputs.Fallback
  ( WrapOuts
  , getFallbackOut
  )
where

import System.IO
import GHC.IO.Encoding
import Monky.Modules

import Monky.Outputs.Ascii
import Monky.Outputs.Utf8

#if MIN_VERSION_base(4,8,0)
#else
import Control.Applicative ((<$>))
#endif

-- |The datatype for wrapping outher outputs
data WrapOuts = forall a . MonkyOutput a => WO a

instance MonkyOutput WrapOuts where
  doLine (WO o) = doLine o


chooseTerminalOut :: IO WrapOuts
chooseTerminalOut = do
  l <- getLocaleEncoding
  if textEncodingName l == "UTF-8"
    then WO <$> getUtf8Out
    else WO <$> getAsciiOut

{- | Wrapper for normal outputs that tries to find the best output

This function will check if stdout is a terminal and switch to AsciiOut or UTf8Out depending on the locale
-}
getFallbackOut
  :: MonkyOutput a
  => IO a -- ^The output to use for non-terminal mode
  -> IO WrapOuts
getFallbackOut o = do
  e <- hIsTerminalDevice stdout
  if e
    then chooseTerminalOut
    else WO <$> o
