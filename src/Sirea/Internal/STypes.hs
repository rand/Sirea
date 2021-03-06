{-# LANGUAGE TypeOperators, EmptyDataDecls,   
    MultiParamTypeClasses, FlexibleInstances #-}

module Sirea.Internal.STypes
    ( (:&:)
    , (:|:)
    , S
    , SigInP
    , SigMembr, BuildMembr(..), buildMembr
    ) where 

import Data.Typeable -- all are typeable

-- | (x :&: y). Product of asynchronous or partitioned signals, but
-- x and y will have equal and tightly coupled active periods. For
-- example, if x is active for 300ms, inactive 100ms, then active
-- 600ms, then y will have the same profile. However, asynchronous
-- delays enable a small divergence of exactly when these periods
-- occur. (They'll be synchronized before recombining signals.)
data (:&:) x y
infixr 3 :&:

-- | (x :|: y). Union or Sum of asynchronous or partitioned signals.
-- Signals are active for different durations, i.e. if x is active
-- 100 ms, inactive 400 ms, then active 100 ms: then y is inactive
-- 100 ms, active up to 400 ms, then inactive 100 ms. (There may be
-- durations where both are inactive.) Due to asynchronous delays 
-- the active periods might overlap for statically known periods.
data (:|:) x y
infixr 2 :|:

-- | (S p a) is a Sig a in partition p. 
--
-- See FRP.Sirea.Signal for a description of signals. RDP developers
-- do not work directly with signals, but rather with behaviors that
-- transform signals. However, a Sirea developer might interact with
-- signals by the `bUnsafeLnk` behavior for FFI and legacy adapters.
--
-- Partitions represent the spatial distribution of signals, across
-- threads, processes, or heterogeneous systems. Developers can keep
-- certain functionality to certain partitions (or classes thereof).
-- Communication between partitions requires explicit behavior, such
-- as bcross.
--
-- Partitions must be Data.Typeable to support analysis of types
-- as values. Some types may have special meaning, indicating that
-- extra threads should be constructed when behavior is initiated.
data S p a

-- might add support for continuous signals? C p x? rather not, though.
-- might add support for collections? (L x) for list of x?


-- | (SigMembr x) supports construction of a membrane object given
-- only the type of signal x. This is necessary for BDynamic and
-- possibly other generic programs that process signals without much
-- knowledge of them. SigMembr can also enforce that a signal is a
-- valid instance of the signal type. SigMembr is entirely defined
-- by sirea-core, no ability to extend it in clients.
class SigMembr x where sigMembr :: (BuildMembr m) => m x

-- | (BuildMembr m) describes construction of a particular membrane.
-- Membranes, in this case, are ignorant about their types. The
-- membrane type determines what is constructed. Note that GADTs
-- might be necessary to leverage this effectively. 
--
-- (developed for use by BDynamic, but client extensible).
class BuildMembr m where
    buildSigMembr :: m (S p a)
    buildSumMembr :: m x -> m y -> m (x :|: y)
    buildProdMembr :: m x -> m y -> m (x :&: y)

instance SigMembr (S p a) where 
    sigMembr = buildSigMembr
instance (SigMembr x, SigMembr y) => SigMembr (x :|: y) where
    sigMembr = buildSumMembr sigMembr sigMembr
instance (SigMembr x, SigMembr y) => SigMembr (x :&: y) where
    sigMembr = buildProdMembr sigMembr sigMembr

-- | Function to build a membrane m for a given signal type x.
buildMembr :: (BuildMembr m, SigMembr x) => m x
buildMembr = sigMembr

-- | (SigInP p x) constrains that complex signal x exists entirely
-- in partition p. This avoids need for implicit bcross in disjoin
-- and eval behaviors, while allowing them to be reasonably generic.
-- 
-- This already has a complete definition. It is not for extension
-- by Sirea clients.
class (SigMembr x) => SigInP p x where
    proofOfSigInP :: ProofOfSigInP p x 

data ProofOfSigInP p x 
trivialSigInP :: ProofOfSigInP p x
trivialSigInP = undefined

instance SigInP p (S p x) where
    proofOfSigInP = trivialSigInP

instance (SigInP p x, SigInP p y) => SigInP p (x :&: y) where
    proofOfSigInP = trivialSigInP

instance (SigInP p x, SigInP p y) => SigInP p (x :|: y) where
    proofOfSigInP = trivialSigInP

-- Data.Typeable support. 

instance Typeable2 S where
    typeOf2 _ = mkTyConApp tycSig []
        where tycSig = mkTyCon3 "sirea-core" "Sirea.Behavior" "S"

instance Typeable2 (:|:) where
    typeOf2 _ = mkTyConApp tycSum []
        where tycSum = mkTyCon3 "sirea-core" "Sirea.Behavior" "(:|:)"

instance Typeable2 (:&:) where
    typeOf2 _ = mkTyConApp tycProd []
        where tycProd = mkTyCon3 "sirea-core" "Sirea.Behavior" "(:&:)"



