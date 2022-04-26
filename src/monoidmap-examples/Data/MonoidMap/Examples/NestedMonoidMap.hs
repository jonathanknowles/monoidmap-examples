{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- |
-- Copyright: © 2022 Jonathan Knowles
-- License: Apache-2.0
--
module Data.MonoidMap.Examples.NestedMonoidMap
    (
--  * Type
      NestedMonoidMap

--  * Construction
    , fromFlatList
    , fromNestedList

--  * Deconstruction
    , toFlatList
    , toNestedList

--  * Queries
    , get
    , keys
    , size

--  * Modification
    , adjust
    , delete
    , set
    )
    where

import Algebra.PartialOrd
    ( PartialOrd (..) )
import Data.Monoid
    ( Sum (..) )
import Data.Monoid.Monus
    ( Monus, OverlappingGCDMonoid )
import Data.Monoid.Null
    ( MonoidNull )
import Data.MonoidMap
    ( MonoidMap )
import Data.Semigroup.Cancellative
    ( Commutative, LeftReductive, RightReductive )
import Data.Set
    ( Set )
import GHC.Exts
    ( IsList (..) )

import qualified Data.Foldable as F
import qualified Data.MonoidMap as MonoidMap
import qualified Data.Set as Set

--------------------------------------------------------------------------------
-- Type
--------------------------------------------------------------------------------

newtype NestedMonoidMap k1 k2 v =
    NestedMonoidMap (MonoidMap k1 (MonoidMap k2 v))
    deriving stock Eq
    deriving newtype
        ( Commutative
        , LeftReductive
        , Monoid
        , MonoidNull
        , Monus
        , OverlappingGCDMonoid
        , PartialOrd
        , RightReductive
        , Semigroup
        , Show
        )

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

fromFlatList
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => [((k1, k2), v)]
    -> NestedMonoidMap k1 k2 v
fromFlatList = F.foldl' acc mempty
  where
    acc m (k, v) = adjust m k (<> v)

fromNestedList
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => [(k1, [(k2, v)])]
    -> NestedMonoidMap k1 k2 v
fromNestedList entries =
    fromFlatList [((k1, k2), v) | (k1, n) <- entries, (k2, v) <- n]

--------------------------------------------------------------------------------
-- Deconstruction
--------------------------------------------------------------------------------

toFlatList
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> [((k1, k2), v)]
toFlatList m = [((k1, k2), v) | (k1, n) <- toNestedList m, (k2, v) <- toList n]

toNestedList
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> [(k1, [(k2, v)])]
toNestedList (NestedMonoidMap m) = fmap toList <$> toList m

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

get :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> (k1, k2)
    -> v
get (NestedMonoidMap m) (k1, k2) = m
    `MonoidMap.get` k1
    `MonoidMap.get` k2

keys
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> Set (k1, k2)
keys = Set.fromList . fmap fst . toFlatList

size :: (Ord k1, Ord k2, Eq v, Monoid v) => NestedMonoidMap k1 k2 v -> Int
size (NestedMonoidMap m) = getSum $ F.foldMap (Sum . MonoidMap.size) m

--------------------------------------------------------------------------------
-- Modification
--------------------------------------------------------------------------------

adjust
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> (k1, k2)
    -> (v -> v)
    -> NestedMonoidMap k1 k2 v
adjust m k f = set m k $ f $ get m k

delete
    :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> (k1, k2)
    -> NestedMonoidMap k1 k2 v
delete m k = set m k mempty

set :: (Ord k1, Ord k2, Eq v, Monoid v)
    => NestedMonoidMap k1 k2 v
    -> (k1, k2)
    -> v
    -> NestedMonoidMap k1 k2 v
set (NestedMonoidMap m) (k1, k2) v = NestedMonoidMap
    $ (m `MonoidMap.set` k1)
    $ (m `MonoidMap.get` k1) `MonoidMap.set` k2
    $ v
