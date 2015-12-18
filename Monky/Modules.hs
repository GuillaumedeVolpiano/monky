{-
    Copyright 2015 Markus Ongyerth, Stephan Guenther

    This file is part of Monky.

    Monky is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Monky is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with Monky.  If not, see <http://www.gnu.org/licenses/>.
-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE CPP #-}
{-|
Module      : Monky.Modules
Description : The module definition used by 'startLoop'
Maintainer  : ongy, moepi
Stability   : experimental
Portability : Linux

This module provides the 'Module' class which is used to define a 'Monky'
compatible module.
-}
module Monky.Modules
(Modules(..), Module(..), pack)
where

#if MIN_VERSION_base(4,8,0)
#else
import Control.Applicative ((<$>))
#endif


import System.Posix.Types (Fd)

-- |A wrapper around module instances so they can be put into a list.
data Modules = forall a . Module a => MW a Int
-- |The type class for modules
class Module a where
    getText :: String -- ^The current user
            -> a -- ^The handle to this module
            -> IO String -- ^The text segment that should be displayed for this module
    getFDs :: a -- ^The handle to this module
           -> IO [Fd] -- ^The 'Fd's to listen on for events
    getFDs _ = return []
    {- |This function is used instead of 'getText' for event triggerd updates.

      The default implementation mappes this to 'getText'
    -}
    getEventText :: Fd -- ^The fd that triggered an event
                 -> String -- ^The current user
                 -> a -- ^The handle to this module
                 -> IO String -- ^The text segment that should be displayed
    getEventText _ = getText

    {- |This is supposed to set up the module
       This is only needed, if the module may fail
       so doing nothing should be ok for all *normal* modules

       The module should return 'True' if the setup was successful (is usable)
       or 'False' if it failed to enter the broken state right at startup
    -}
    setupModule :: a -> IO Bool
    setupModule _ = return True

    {- |This function is a wrapper around 'getText' that allows
        modules to report a fail and go into a failed state -}
    getTextFailable :: String -> a -> IO (Maybe String)
    getTextFailable u h = Just <$> getText u h
    {- |This function is a wrapper around 'getEventText' that allows
        modules to report a fail and go into a failed state -}
    getEventTextFailable :: Fd -> String -> a -> IO (Maybe String)
    getEventTextFailable f u h = Just <$> getEventText f u h

    {- |If a module failed earlier this will be called in periodicly
       until the module returns true to indicate a successful recovery -}
    recoverModule :: a -> IO Bool
    recoverModule _ = return True

-- |Function to make packaging modules easier
pack :: Module a
     => Int -- ^The refresh rate for this module
     -> IO a -- ^The function to get a module (get??Handle)
     -> IO Modules -- ^The packed module ready to be given to 'startLoop'
pack i = fmap (flip MW i)
