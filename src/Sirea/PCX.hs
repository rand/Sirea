{-# LANGUAGE EmptyDataDecls, Rank2Types #-}

-- | PCX - declarative resource linking mechanism for Haskell.
--
-- RDP has a conservative notion of resources: services, resources,
-- shared state, etc. are external to behaviors; nothing is created,
-- nothing is destroyed. Developers will use discovery idioms, paths
-- and names. RDP is effectful, so there is no semantic concern with
-- initializing resources after they are discovered. 
--
-- A useful idiom: abstract infinite spaces of resources, and lazily
-- initialize resources (if necessary) as they are discovered.
--
-- It is easy to partition infinite space into more infinite spaces.
-- Every RDP application can thus have its own, infinite corner of 
-- the universe. This is compatible with the perspective that it is 
-- RDP "all the way down" - an RDP application is a dynamic behavior
-- that manipulates resources in a dedicated partition.
--
-- Sirea models this by use of the PCX type.
--
-- The idea with PCX is to present resources as though they already
-- exist, as though PCX is just a very large namespace. Thus, PCX 
-- provides a pure interface - all you can do is look up resources.
-- (But it makes extensive use of unsafePerformIO under the hood.)
--
-- PCX is most useful for volatile resources, which will not survive
-- destruction of the Haskell process. Persistent resources benefit
-- by use of volatile proxies, e.g. to cache a value. PCX is used in
-- Sirea core for threads and hooking up communication between them.
--
-- But it could also support creating a GLUT thread, and hooking it
-- up to RDP behaviors so they can demand a window, add contents to
-- a window, observe framerate, etc.
--
-- NOTE: Threading PCX through an application would grow irritating.
-- However, a simple behavior transformer can make it a lot nicer.
-- Another module in Sirea will provide the BCX type to carry an
-- initial PCX to every element in a behavior.
-- 
module Sirea.PCX
    ( PCX    -- abstract
    , newPCX -- a new toplevel
    , findIn -- the lookup function
    , Resource(..)
    ) where

import Data.Typeable

-- | PCX p - Partition Context. Abstract.
--
-- A Partition context is an infinite space of resources, but holds
-- only one resource of each type. For more resources of a given 
-- type, consider using:
--   * find a child PCX, then look for the same resource there
--   * a newtype with a phantom type (per instance)
--   * a resource representing a mutable collection
--
data PCX p = PCX { inPCX :: (Resource r) => r }

{-
    pcx_ident :: [TypeRep]
    , pcx_store :: IORef (
-}

-- | Resource - found inside a PCX. 
--
-- Resources are constructed in IO, but developers should protect an
-- illusion that resources existed prior the locator operation, i.e.
-- we are locating resources, not creating them. This requires there
-- be no observable side-effects in the locator, and that resources 
-- are passive at least until another operation is called on them.
--
-- The locator has recursive access to other resources, and to an
-- argument representing the unique ID of that resource (up to the
-- newPCX, anyway).
class (Typeable r) => Resource r where
    locateResource :: [TypeRep] -> PCX p -> IO r

-- | findIn pcx - obtain any Resource.
findIn :: (Resource r) => PCX p -> r
findIn = inPCX

-- | newPCX - a `new` PCX space, unique and fresh. 
-- 
-- While developers could create more than one, one is sufficient.
newPCX :: IO (PCX p)
newPCX = undefined





