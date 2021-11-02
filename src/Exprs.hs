module Exprs where

data UsProgs =
    UsProgExec UsTm
  | UsProgFun String Type UsTm UsProgs
  | UsProgExtern String Type UsProgs
  | UsProgData String [Ctor] UsProgs
  deriving (Eq, Ord)

data Prog = ProgFun Var [(Var, Type)] Term Type | ProgExtern Var String [Type] Type | ProgData Var [Ctor]
  deriving (Eq, Ord)
data Progs = Progs [Prog] Term
  deriving (Eq, Ord)

data Ctor = Ctor Var [Type]
  deriving (Eq, Ord)

type Var = String

type Param = (Var, Type)
type Arg = (Term, Type)

data Dist =
    DistFail
  | DistUni
  | DistAmb
  deriving (Eq, Ord)

data UsTm = -- User Term
    UsVar Var
  | UsLam Var Type UsTm
  | UsApp UsTm UsTm
  | UsCase UsTm [CaseUs]
  | UsSamp Dist Type
  | UsLet Var UsTm UsTm
  | UsAmb [UsTm]
  | UsAmpIn [UsTm]
  | UsAmpOut UsTm Int
  | UsProdIn [UsTm]
  | UsProdOut UsTm [Var] UsTm
  deriving (Eq, Ord)

data GlobalVar = CtorVar | DefVar
  deriving (Eq, Ord)

data Term =
    TmVarL Var Type -- Local var
  | TmVarG GlobalVar Var [Arg] Type -- Global var
  | TmLam Var Type Term Type
  | TmApp Term Term Type {- -> -} Type
  | TmLet Var Term Type Term Type
  | TmCase Term Var [Case] Type
  | TmSamp Dist Type
  | TmAmb [Term] Type
  | TmAmpIn [Arg]
  | TmAmpOut Term [Type] Int
  | TmProdIn [Arg]
  | TmProdOut Term [Param] Term Type
  deriving (Eq, Ord)

data Type =
    TpArr Type Type
  | TpVar Var
  | TpAmp [Type]
  | TpProd [Type]
  deriving (Eq, Ord)

data CaseUs = CaseUs Var [Var] UsTm
  deriving (Eq, Ord)

data Case = Case Var [Param] Term
  deriving (Eq, Ord)