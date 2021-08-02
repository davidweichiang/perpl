module Free where
import Exprs
import Ctxt
import Util
import qualified Data.Map as Map
import Data.List
import Data.Char

-- For checking linearity, vars can appear:
-- LinNo: not at all
-- LinYes: just once
-- LinErr: multiple times
data Lin = LinNo | LinYes | LinErr
  deriving Eq

linIf :: Lin -> a -> a -> a -> a
linIf LinYes y n e = y
linIf LinNo  y n e = n
linIf LinErr y n e = e

linIf' :: Lin -> Lin -> Lin -> Lin
linIf' i y n = linIf i y n LinErr


-- Returns a map of the free vars in a term, with the max number of occurrences
freeVars :: UsTm -> Map.Map Var Int
freeVars (UsVar x) = Map.singleton x 1
freeVars (UsLam x tp tm) = Map.delete x $ freeVars tm
freeVars (UsApp tm tm') = Map.unionWith (+) (freeVars tm) (freeVars tm')
freeVars (UsCase tm cs) = foldr (Map.unionWith max . freeVarsCase) (freeVars tm) cs
freeVars (UsSamp d tp) = Map.empty
freeVars (UsLet x tm tm') = Map.unionWith max (freeVars tm) (Map.delete x $ freeVars tm')

freeVars' :: Term -> Map.Map Var Type
freeVars' (TmVarL x tp) = Map.singleton x tp
freeVars' (TmVarG gv x as tp) = freeVarsArgs' as
freeVars' (TmLam x tp tm tp') = Map.delete x $ freeVars' tm
freeVars' (TmApp tm1 tm2 tp2 tp) = Map.union (freeVars' tm1) (freeVars' tm2)
freeVars' (TmLet x xtm xtp tm tp) = Map.union (freeVars' xtm) (Map.delete x (freeVars' tm))
freeVars' (TmCase tm tp cs tp') = Map.union (freeVars' tm) (freeVarsCases' cs)
freeVars' (TmSamp d tp) = Map.empty
freeVars' (TmFold fuf tm tp) = freeVars' tm

freeVarsCase :: CaseUs -> Map.Map Var Int
freeVarsCase (CaseUs c xs tm) = foldr Map.delete (freeVars tm) xs

freeVarsCase' :: Case -> Map.Map Var Type
freeVarsCase' (Case c as tm) = foldr (Map.delete . fst) (freeVars' tm) as

freeVarsCases' :: [Case] -> Map.Map Var Type
freeVarsCases' = foldr (Map.union . freeVarsCase') Map.empty

freeVarsArgs' :: [Arg] -> Map.Map Var Type
freeVarsArgs' = Map.unions . map (freeVars' . fst)


-- Returns the (max) number of occurrences of x in tm
freeOccurrences :: Var -> UsTm -> Int
freeOccurrences x tm = Map.findWithDefault 0 x (freeVars tm)

-- Returns if x appears free in tm
isFree :: Var -> UsTm -> Bool
isFree x tm = Map.member x (freeVars tm)

-- Returns if x occurs at most once in tm
isAff :: Var -> UsTm -> Bool
isAff x tm = freeOccurrences x tm <= 1

-- Returns if x appears exactly once in tm
isLin :: Var -> UsTm -> Bool
isLin x tm = h tm == LinYes where
  linCase :: CaseUs -> Lin
  linCase (CaseUs x' as tm') = if any ((==) x) as then LinNo else h tm'
  
  h :: UsTm -> Lin
  h (UsVar x') = if x == x' then LinYes else LinNo
  h (UsLam x' tp tm) = if x == x' then LinNo else h tm
  h (UsApp tm tm') = linIf' (h tm) (linIf' (h tm') LinErr LinYes) (h tm')
  h (UsCase tm []) = h tm
  h (UsCase tm cs) = linIf' (h tm)
    -- make sure x is not in any of the cases
    (foldr (\ c -> linIf' (linCase c) LinErr) LinYes cs)
    -- make sure x is linear in all the cases, or in none of the cases
    (foldr (\ c l -> if linCase c == l then l else LinErr) (linCase (head cs)) (tail cs))
  h (UsSamp d tp) = LinNo
  h (UsLet x' tm tm') =
    if x == x' then h tm else linIf' (h tm) (linIf' (h tm') LinErr LinYes) (h tm')

typeIsRecursive :: Ctxt -> Type -> Bool
typeIsRecursive g = h [] where
  h visited (TpVar y) =
    y `elem` visited ||
      maybe False
        (any $ \ (Ctor _ tps) -> any (h (y : visited)) tps)
        (ctxtLookupType g y)
  h visited (TpArr tp1 tp2) = h visited tp1 || h visited tp2
  h visited (TpMaybe tp) = h visited tp
  h visited TpBool = False
