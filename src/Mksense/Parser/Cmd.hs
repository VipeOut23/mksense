module Mksense.Parser.Cmd where

import Mksense.Cmd
import Mksense.Parser.Core
import Mksense.Parser.Common
import Mksense.Logic.Data
import Control.Applicative
import Control.Monad


flag :: String -> Parser String
flag s = do
  mplus (string "--") (string s)
  spaces
  return s

flags :: Options -> Parser Options
flags o = do
  f <- flag "human" <|> flag "brief"
  return $ case f of
    "human" -> o { scheme = Human }
    "brief" -> o { scheme = Brief }

allFlags :: Options -> Parser Options
allFlags o = Parser $ \s -> internal s
  where internal s = case parse (flags o) s of
                [] -> parse (return o) s
                [(a,s)] -> parse (allFlags a) s

modes :: Options -> Parser Options
modes o = do
  m <- reserved "orand" <|> reserved "nnf" <|> reserved "cnf" <|> reserved "dnf" <|> reserved "clauses" <|> reserved "show"
  return $ case m of
    "orand"   -> o { orand = True }
    "nnf"     -> o { nnf = True }
    "cnf"     -> o { cnf = True }
    "dnf"     -> o { dnf = True }
    "clauses" -> o { clauses = True }
    "show"    -> o { orand = False, nnf = False, cnf = False, clauses = False }

allModes :: Options -> Parser Options
allModes o = Parser $ \s -> internal s
  where internal s = case parse (modes o) s of
                [] -> parse (return o) s
                [(a,s)] -> parse (allModes a) s

options :: Parser Options
options = do
  opts <- allFlags defaultOptions
  opts <- allModes opts
  return opts


run :: String -> Options
run s = case parse options s of
  [(res, [])] -> res
  [(res, rs)] -> res { rest = rs }
  _           -> error "Couldn't parse Arguments!"
