-- |
-- Copyright: © 2022–2023 Jonathan Knowles
-- License: Apache-2.0
--
-- A lawful implementation of 'MultiMap', implemented in terms of 'Map' and
-- 'NESet'.
--
module Examples.MultiMap.MultiMap3 where

import Prelude hiding
    ( lookup )

import Data.Map.Strict
    ( Map )
import Data.Maybe
    ( mapMaybe )
import Data.Set.NonEmpty
    ( NESet )
import Examples.MultiMap
    ( MultiMap (..) )

import qualified Data.Map.Merge.Strict as Map
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Set.NonEmpty as NESet

newtype MultiMap3 k v = MultiMap (Map k (NESet v))
    deriving stock (Eq, Show)

instance (Ord k, Ord v) => MultiMap MultiMap3 k v where

    fromList
        = MultiMap
        . Map.fromListWith (<>)
        . mapMaybe (traverse NESet.nonEmptySet)

    toList (MultiMap m) = fmap NESet.toSet <$> Map.toList m

    empty = MultiMap Map.empty

    lookup k (MultiMap m) = maybe Set.empty NESet.toSet (Map.lookup k m)

    null (MultiMap m) = Map.null m

    nonNull (MultiMap m) = not (Map.null m)

    nonNullKey k (MultiMap m) = Map.member k m

    nonNullKeys (MultiMap m) = Map.keysSet m

    nonNullCount (MultiMap m) = Map.size m

    isSubmapOf (MultiMap m1) (MultiMap m2) =
        Map.isSubmapOfBy NESet.isSubsetOf m1 m2

    update k vs (MultiMap m) =
        case NESet.nonEmptySet vs of
            Nothing -> MultiMap (Map.delete k    m)
            Just zs -> MultiMap (Map.insert k zs m)

    insert k vs (MultiMap m) =
        case NESet.nonEmptySet (lookup k (MultiMap m) `Set.union` vs) of
            Nothing -> MultiMap (Map.delete k    m)
            Just zs -> MultiMap (Map.insert k zs m)

    remove k vs (MultiMap m) =
        case NESet.nonEmptySet (lookup k (MultiMap m) `Set.difference` vs) of
            Nothing -> MultiMap (Map.delete k    m)
            Just zs -> MultiMap (Map.insert k zs m)

    union (MultiMap m1) (MultiMap m2) = MultiMap $
        Map.unionWith NESet.union m1 m2

    intersection (MultiMap m1) (MultiMap m2) = MultiMap $
        Map.merge
            Map.dropMissing
            Map.dropMissing
            (Map.zipWithMaybeMatched mergeValues)
            m1
            m2
      where
        mergeValues :: Ord v => k -> NESet v -> NESet v -> Maybe (NESet v)
        mergeValues _k s1 s2 = NESet.nonEmptySet (NESet.intersection s1 s2)
