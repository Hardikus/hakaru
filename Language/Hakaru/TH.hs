{-# LANGUAGE TemplateHaskell, FlexibleInstances, MultiParamTypeClasses #-}
module Language.Hakaru.TH (THRepr, unTHRepr, show_code) where

import Prelude hiding (Real)

import Language.Hakaru.Syntax
import Language.Haskell.TH

newtype THRepr a = THR { unTHRepr :: ExpQ }

liftT :: Name -> [ExpQ] -> THRepr a
liftT n es = THR (foldl appE (varE n) es)

liftL :: [ExpQ] -> ExpQ
liftL []     = varE '[]
liftL (e:es) = varE '(:) `appE` e `appE` liftL es

-- liftF takes a function on THRepr values and uses it to generate a lambda expression for acting on repr values.
liftF :: (THRepr a -> THRepr b) -> ExpQ
liftF f = do x <- newName "x"
             lamE [varP x] (unTHRepr (f (THR (varE x))))

liftF2 :: (THRepr a -> THRepr b -> THRepr c) -> ExpQ
liftF2 f = do x <- newName "x"
              y <- newName "y"
              lamE [varP x, varP y] (unTHRepr (f (THR (varE x)) (THR (varE y))))

instance Order THRepr a where
  less (THR e) (THR e') = liftT 'less [e, e']

instance Base THRepr where
  unit = liftT 'unit []
  pair (THR e) (THR e') = liftT 'pair [e, e']
  unpair (THR e) f = liftT 'unpair [liftF2 f]
  inl (THR e) = liftT 'inl [e]
  inr (THR e) = liftT 'inr [e]
  uneither (THR e) f g = liftT 'uneither [liftF f, liftF g]
  true = liftT 'true []
  false = liftT 'false []
  if_ (THR b) (THR t) (THR e) = liftT 'if_ [b,t,e]
  unsafeProb (THR e) = liftT 'unsafeProb [e]
  fromProb (THR e) = liftT 'fromProb [e]
  betaFunc (THR e) (THR e') = liftT 'betaFunc [e, e']

instance Num (THRepr Real) where
  (THR e) + (THR e') = liftT '(+) [e, e']
  (THR e) * (THR e') = liftT '(+) [e, e']
  abs (THR e) = liftT 'abs [e]
  signum (THR e) = liftT 'signum [e]
  fromInteger n = liftT 'fromInteger [litE (IntegerL n)]
  negate (THR e) = liftT 'negate [e]
  (THR e) - (THR e') = liftT '(-) [e, e']

instance Fractional (THRepr Real) where
  fromRational r = liftT 'fromRational [litE (RationalL r)]
  recip (THR e) = liftT 'recip [e]
  (THR e) / (THR e') = liftT '(/) [e, e']

instance Floating (THRepr Real) where
  pi = liftT 'pi []
  exp (THR e) = liftT 'exp [e]
  log (THR e) = liftT 'log [e]
  sqrt (THR e) = liftT 'sqrt [e]
  (THR e) ** (THR e') = liftT '(**) [e,e']
  logBase (THR e) (THR e') = liftT 'logBase [e,e']
  sin (THR e) = liftT 'sin [e]
  cos (THR e) = liftT 'cos [e]
  tan (THR e) = liftT 'tan [e]
  asin (THR e) = liftT 'asin [e]
  acos (THR e) = liftT 'acos [e]
  atan (THR e) = liftT 'atan [e]
  sinh (THR e) = liftT 'sinh [e]
  cosh (THR e) = liftT 'cosh [e]
  tanh (THR e) = liftT 'tanh [e]
  asinh (THR e) = liftT 'asinh [e]
  acosh (THR e) = liftT 'acosh [e]
  atanh (THR e) = liftT 'atanh [e]

instance Num (THRepr Prob) where
  (THR e) + (THR e') = liftT '(+) [e, e']
  (THR e) * (THR e') = liftT '(+) [e, e']
  abs (THR e) = liftT 'abs [e]
  signum (THR e) = liftT 'signum [e]
  fromInteger n = liftT 'fromInteger [litE (IntegerL n)]
  negate (THR e) = liftT 'negate [e]
  (THR e) - (THR e') = liftT '(-) [e, e']

instance Fractional (THRepr Prob) where
  fromRational r = liftT 'fromRational [litE (RationalL r)]
  recip (THR e) = liftT 'recip [e]
  (THR e) / (THR e') = liftT '(/) [e, e']

instance Mochastic THRepr where
  dirac (THR e) = liftT 'dirac [e]
  bind (THR e) f = liftT 'bind [e, liftF f]
  lebesgue = liftT 'lebesgue []
  superpose pms = liftT 'superpose [liftL [ varE '(,) `appE` e `appE` e'
                                          | (THR e, THR e') <- pms ]]
  uniform (THR e) (THR e') = liftT 'uniform [e, e']
  normal (THR e) (THR e') = liftT 'normal [e, e']
  factor (THR e) = liftT 'factor [e]
  mix pms = liftT 'mix [liftL [ varE '(,) `appE` e `appE` e'
                              | (THR e, THR e') <- pms ]]
  categorical l = liftT 'categorical [liftL [ varE '(,) `appE` e `appE` e'
                                            | (THR e, THR e') <- l ]]

instance Disintegrate THRepr where
  disintegrate (THR e) (THR e') (THR e'') = liftT 'disintegrate [e, e', e'']

instance Lambda THRepr where
  lam f = liftT 'lam [liftF f]
  app (THR e) (THR e') = liftT 'app [e, e']

show_code :: THRepr a -> IO ()
show_code (THR cde) = runQ cde >>= putStrLn . pprint