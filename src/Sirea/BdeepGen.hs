
-- | BdeepGen is a utility program to generate Bdeep.hs
-- I don't try to be efficient here... just productive.
module Main where

import Control.Exception (assert)

depth :: Int
depth = 4


infixr 4 +\
(+\) :: String -> String -> String
hd +\ tl = hd ++ "\n-- " ++ tl

deepThoughts, deepHeader :: String

deepThoughts = 
    "-- NOTE: This file is generated programmatically, and should not be \n" ++
    "-- modified by hand. Modify and rerun BdeepGen instead.\n\n" ++
    "                           " +\
    "| Bdeep provides convenient shorthand utility behaviors,  simple" +\
    "composites of RDP behaviors for: " +\
    "                           " +\
    "  deep application of behaviors " +\
    "  deep extraction of products " +\
    "                           " +\
    "For example, rather than:  " +\
    "                           " +\
    "> (bfirst . bsecond . bleft . bsecond) action " +\
    "                           " +\
    "Developers can simply write: " +\
    "                           " +\
    "> bonfsls action           " +\
    "                           " +\
    "This reads as `behavior on first second left second`. Note that" +\
    "the order of characters corresponds to the path of application." +\
    "These are defined up to 4 deep, for a total 340 functions. The" +\
    "shallow elements bonf (= bfirst), bons, bonl, bonr are included" +\
    "for consistency.           " +\
    "                           " +\
    "Similarly, rather than:    " +\
    "                           " +\
    "> bfst >>> bsnd >>> bfst >>> bfst" +\
    "                           " +\
    "Developers can write:      " +\
    "                           " +\
    "> bxfsff                   " +\
    "                           " +\
    "This reads as `behavior extract first second first first second." +\
    "The forward order of characters corresponds to the path. This is" +\
    "reverse the order of Lisp's car,cdr,cadadr conventions. " +\
    "                           " +\
    "To extract multiple elements, use the (&&&) behavior: " +\
    "                           " +\
    " > bxfsfs &&& bxssfs       " +\
    "                           " +\
    "Note: extraction is NOT possible for left/right, due to duration " +\
    "coupling constraints. These are also defined up to 4 depth, for " +\
    "total 32 functions.       " +\
    "                          " +\
    "The dual of bx* is also provided, for completeness and another 30" +\
    "functions for injection - `binlrr` is `binl <<< binr <<< binr`." +\
    "These might be useful if a behavior is a big switch, but that may " +\
    "be an anti-pattern (better to use a lot of small behaviors)." +\
    "                           " +\
    "If 4 depth isn't enough, these operations are readily composed." +\
    "E.g. consider a stack-like environment:" +\
    "  extract 8th element: bxssss >>> bxsssf " +\
    "  operate on 8th element: (bonssss . bonsssf) op " +\
    "Though FRP.Sirea.Bstack provides richer Forth-inspired operators" +\
    "for pointfree stack operations." +\
    "                           " +\
    "Unfortunately, RDP behaviors are not compatible with Haskell's " +\
    "Arrow syntax, which would make it easier to provide local names" +\
    "to complex parameters. At the moment, Sirea must be used in a" +\
    "point-free style. These deep operations should keep this from" +\
    "becoming too tedious.      " +\ 
    "                           " +\
    "See Also:                  " +\
    "  FRP.Sirea.Behavior       " +\
    "  FRP.Sirea.Bstack         " +\
    "                           "

allCombosOfSize :: Int -> [x] -> [[x]]
allCombosOfSize _ [] = []
allCombosOfSize n xs = 
    assert(n > 0) $
    if (n < 2) then map (:[]) xs else 
    xs `across` allCombosOfSize (n-1) xs
    where across :: [x] -> [[x]] -> [[x]]
          across [] _ = []
          across (x:xs) combos = map (x:) combos ++ xs `across` combos

allCombosUpToSize :: Int -> [x] -> [[x]]
allCombosUpToSize n xs = 
    if (n < 1) then [] else
    allCombosUpToSize (n-1) xs ++ allCombosOfSize n xs
    

chunksOf :: Int -> [x] -> [[x]]
chunksOf _ [] = []
chunksOf n xs = assert (n > 0) $ (take n xs):(chunksOf n $ drop n xs)

deepAppFunctions, deepExtractFunctions, deepInjectFunctions, allFunctions :: [String]
deepAppFunctions = map ("bon"++)    $ allCombosUpToSize depth "fslr"
deepExtractFunctions = map ("bx"++) $ allCombosUpToSize depth "fs"
deepInjectFunctions = map ("bin"++) $ allCombosUpToSize depth "lr"
allFunctions = deepExtractFunctions ++ deepInjectFunctions ++ deepAppFunctions

deepHeader = 
    "{-# LANGUAGE TypeOperators #-} \n" ++
    "module FRP.Sirea.Bdeep \n" ++
    "    ( " ++ listFunctions ++ "\n" ++
    "    ) where \n" ++ 
    "import Control.Category ((<<<))\n" ++
    "import FRP.Sirea.Behavior \n\n"
    where separated sep xs = foldl (\ln s -> ln ++ sep ++ s) (head xs) (tail xs) 
          listFunctions = 
            let namesPerLine = chunksOf 6 allFunctions in 
            let linesOfNames = map (separated ", ") namesPerLine in
            separated "\n    , " linesOfNames

buildHd, buildFn, bonType, binType, bxType, bonBody, binBody, bxBody :: String -> String

buildHd ('b':'o':'n':fslr) = bonType fslr
buildHd ('b':'i':'n':lr) = if(length lr > 1) then binType lr else binComment
    where binComment = "-- bin" ++ lr ++ " is defined in FRP.Sirea.Behavior."
buildHd ('b':'x':fs) = bxType fs
buildHd s = error $ "unknown function: " ++ s

buildFn ('b':'o':'n':fslr) = bonBody fslr
buildFn ('b':'i':'n':lr) = binBody lr
buildFn ('b':'x':fs) = bxBody fs
buildFn s = error $ "unknown function: " ++ s

bonType fslr = "bon" ++ fslr ++ " :: " ++ genClass ++ " b e e' -> b " ++ stype fslr "e " ++ " " ++ stype fslr "e'"
    where genClass = bonClass False False fslr
binType lr = "bin" ++ lr ++ " :: (BSum b) => b e " ++ stype lr "e "
bxType fs = "bx" ++ fs ++ " :: (BProd b) => b " ++ stype fs "e " ++ " e"

bonClass :: Bool -> Bool -> String -> String
bonClass bfs blr [] = 
    if (bfs && blr) then "(BProd b, BSum b) =>"
    else if(bfs) then    "(BProd b        ) =>"
    else if(blr) then    "(         BSum b) =>"
    else error "illegal path"
bonClass bfs blr ('f':path) = bonClass True blr path
bonClass bfs blr ('s':path) = bonClass True blr path
bonClass bfs blr ('l':path) = bonClass bfs True path
bonClass bfs blr ('r':path) = bonClass bfs True path
bonClass _ _ _ = error "illegal signal type"



bonBody "f" = "bonf = bfirst  -- for consistent naming"
bonBody "s" = "bons = bsecond -- for consistent naming"
bonBody "l" = "bonl = bleft   -- for consistent naming"
bonBody "r" = "bonr = bright  -- for consistent naming"
bonBody s@(x:xs) = "bon" ++ s ++ " = bon" ++ [x] ++ " . bon" ++ xs

binBody "l" = "-- binl already defined in FRP.Sirea.Behavior."
binBody "r" = "-- binr already defined in FRP.Sirea.Behavior."
binBody s@(x:xs) = "bin" ++ s ++ " = bin" ++ [x] ++ " <<< bin" ++ xs

bxBody "f"  = "bxf = bfst     -- for consistent naming"
bxBody "s"  = "bxs = bsnd     -- for consistent naming"
bxBody s@(x:xs) = "bx" ++ s ++ " = bx" ++ [x] ++ " >>> bx" ++ xs

-- otype : the opposite side of the stype.
otype :: String -> String
otype (x:xs) = opp x ++ (show . length) xs
    where opp 'l' = "r"
          opp 'r' = "l"
          opp 'f' = "s"
          opp 's' = "f"
          opp _ = error $ "illegal signal structure " ++ (x:xs)

-- represent a complex signal type
stype :: String -> String -> String
stype []         e = e
stype s@('l':xs) e = "(" ++ stype xs e ++ " :|: " ++ otype s ++ ")"
stype s@('r':xs) e = "(" ++ otype s ++ " :|: " ++ stype xs e ++ ")"
stype s@('f':xs) e = "(" ++ stype xs e ++ " :&: " ++ otype s ++ ")"
stype s@('s':xs) e = "(" ++ otype s ++ " :&: " ++ stype xs e ++ ")"
stype s          _ = error $ "illegal signal structure " ++ s

main :: IO ()
main = 
    putStrLn deepThoughts >>
    putStrLn deepHeader >>
    putStrLn (unlines $ map buildHd allFunctions) >>
    putStrLn (unlines $ map buildFn allFunctions) >>
    return ()



