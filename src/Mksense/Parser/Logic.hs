module Mksense.Parser.Logic where

import Mksense.Parser.Core
import Mksense.Logic.Data
import Data.Char
import Data.Maybe
import Control.Applicative

oneOf :: [Parser a] -> Parser a
oneOf s = foldr (<|>) empty s

char :: Char -> Parser Char
char c = satisfy (c ==)

nchar :: Char -> Parser Char
nchar c = satisfy (c /=)

string :: String -> Parser String
string [] = return []
string (c:cs) = do { char c; string cs; return (c:cs)}

token :: Parser a -> Parser a
token p = do { a <- p; spaces ; return a}

reserved :: String -> Parser String
reserved s = token (string s)

spaces :: Parser String
spaces = many . satisfy $ flip elem " \n\r"

alphanum :: Parser Char
alphanum = satisfy isAlphaNum

quoteStr :: Parser String
quoteStr = do
  q <- oneOf $ map char qs
  s <- many $ nchar q
  char q
  return s
  where qs = ['\"', '\'']

parens :: Parser Expression -> Parser Expression
parens m = do
  u <- unar
  spaces
  p <- oneOf $ map (reserved . fst) ps
  n <- m
  spaces
  reserved $ fromJust $ lookup p ps
  return $ n {unary=u}
  where ps = [("(",")"), ("[","]"), ("{","}"), ("<",">")]

unar :: Parser (Maybe Unary)
unar = do
  u <- oneOf [string "not", string "-", string "!"] <|> return []
  return $ (case u of []  -> Nothing ; _ -> Just Negate)

literal :: Parser Expression
literal = do
  u <- unar
  spaces
  l <- quoteStr <|> some alphanum
  spaces
  return $ Literal u (Right l)

expr :: Parser Expression
expr = oneOf [equivOp, impliesOp, orOp, andOp, xorOp, nandOp, atom]

atom :: Parser Expression
atom = parens expr <|> literal

infixOp :: [String] -> Operator -> Parser Expression
infixOp s o = do
  spaces
  a <- atom
  oneOf $ map reserved s
  b <- atom
  return $ Composed Nothing a o b


orOp :: Parser Expression
orOp = infixOp ["or", "||"] Or

andOp :: Parser Expression
andOp = infixOp ["and", "&&", "&"] And

impliesOp :: Parser Expression
impliesOp = infixOp ["=>", "->", "implies", "impl"] Implies

equivOp :: Parser Expression
equivOp = infixOp ["<=>", "=", "==", "<->", "equiv", "eq", "equivalent"] Equivalent

nandOp :: Parser Expression
nandOp = infixOp ["nand", "!&"] Nand

xorOp :: Parser Expression
xorOp = infixOp ["xor"] Xor


run :: String -> Expression
run = runParser expr
