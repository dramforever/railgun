{-# LANGUAGE GeneralizedNewtypeDeriving #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Network.Railgun.Types
-- Copyright   :  (c) 2015 dramforever
-- License     :  BSD3 (see file LICENSE)
--
-- Maintainer  :  dramforever <dramforever@live.com>
-- Stability   :  experimental
-- Portability :  non-portable (GHC extensions)
--
-- Basic types, instances and functions about 'Railgun'
--
-----------------------------------------------------------------------------

module Network.Railgun.Internal
       ( -- * The 'Railgun' monad
         Railgun(..)
       , railgunCallCC

         -- * Interface to WAI
       , RailgunApp
       , runRailgunApp
       ) where

import Network.Wai

-- | The main monad. It's like 'Application' from WAI but 'Response' became
-- a type parameter
newtype Railgun a = Railgun {
  runRailgun :: Request -> (a -> IO ResponseReceived) -> IO ResponseReceived
}

instance Monad Railgun where
  return a = Railgun $ \_ ret -> ret a
  Railgun m >>= f = Railgun $ \req ret ->
    m req (\a -> runRailgun (f a) req ret)

-- | Since 'Railgun' is in continuation passing style this function might
-- be useful. Who knows.
railgunCallCC :: ((a -> Railgun b) -> Railgun a) -> Railgun a
railgunCallCC f = Railgun $ \req ret ->
  runRailgun (f $ \x -> Railgun $ \_ _ -> ret x) req ret

-- | A 'RailgunApp' is a full application that can be unwrapped
-- by 'runRailgunApp'
type RailgunApp = Railgun Response

-- | Unwrap a 'RailgunApp' so that you can pass it to a WAI handler or a
-- middleware
runRailgunApp :: RailgunApp -> Application
runRailgunApp = runRailgun
