{-# LANGUAGE TypeFamilies, Rank2Types, FlexibleContexts #-}
module Tests.RoundTrip(allTests) where

import Prelude hiding (Real)

import qualified System.Random.MWC as MWC
import qualified Data.Number.LogFloat as LF

import Language.Hakaru.Syntax
import Language.Hakaru.Disintegrate
import Language.Hakaru.Sample
import Language.Hakaru.Expect (Expect(unExpect), Expect', normalize)
-- import Language.Hakaru.Maple (Maple, runMaple)
-- import Language.Hakaru.Simplify (simplify)
import Language.Hakaru.PrettyPrint (runPrettyPrint)
-- import Text.PrettyPrint (text, (<>), ($$), nest, render)

import Test.HUnit
import Tests.TestTools

-- mikek: some tests are ignored because they crash ghci for me

testMeasureUnit :: Test
testMeasureUnit = test [
    "t1,t5"   ~: testSS [t1,t5] (factor (1/2)),
    "t10"     ~: testSS [t10] (superpose []),
    "t11,t22" ~: testSS [t11,t22] (dirac unit),
    "t12"     ~: testSS [] t12,
    "t20"     ~: testSS [t20] (lam (\y -> factor (y*(1/2)))),
    "t24"     ~: testSS [t24] t24',
    "t25"     ~: testSS [t25] t25'
    ]

testMeasureProb :: Test
testMeasureProb = test [
    "t2"  ~: testSS [t2] (uniform 0 1 `bind` dirac . unsafeProb),
    "t26" ~: ignore $ testMaple t26,
    "t30" ~: testSS [] t30,
    "t33" ~: testSS [] t33,
    "t34" ~: testSS [t34] (dirac 3),
    "t35" ~: testSS [t35] (lam (\x -> if_ (less x 4) (dirac 3) (dirac 5))),
    "t38" ~: testSS [] t38,
    "t42" ~: testSS [t42] (dirac 1)
    ]

testMeasureReal :: Test
testMeasureReal = test [
    "t3"  ~: testSS [] t3,
    "t6"  ~: testSS [] t6,
    "t7"  ~: testSS [t7] t7',
    "t7n" ~: testSS [t7n] t7n',
    "t9"  ~: testSS [t9] (uniform 3 7 `bind` \x -> superpose [(2, dirac x)]),
    "t13" ~: testSS [t13] t13',
    "t14" ~: testSS [t14] t14',
    "t21" ~: ignore $ testS t21,
    "t27" ~: testSS t27 t27',
    "t28" ~: testSS [] t28,
    "t29" ~: testSS [] t29,
    "t31" ~: testSS [] t31,
    "t32" ~: testSS [] t32,
    "t36" ~: testSS [] t36,
    "t37" ~: testSS [] t37,
    "t39" ~: testSS [] t39,
    "t40" ~: testSS [] t40
    ]

testMeasurePair :: Test
testMeasurePair = test [
    "t4"  ~: testS t4,
    "t8"  ~: testSS [] t8,
    "t23" ~: testSS [t23] t23'
    ]

testOther :: Test
testOther = test [
    "testMcmc" ~: testMcmc,
    "testGibbs1" ~: testSS [testGibbsProp1] (lam $ \x -> normal x 1),
    "testGibbs2" ~: testSS [testGibbsProp2] (lam $ \x -> normal (x/2) (sqrt_ (1/2))),
    "expr1" ~: testMaple expr1,
    "expr2" ~: testMaple expr2,
    "expr4" ~: testMaple expr4,
    "testKernel" ~: testMaple testKernel,
    "testKernel2" ~: testMaple testKernel2
    ]

allTests :: Test
allTests = test [
    testMeasureUnit,
    testMeasureProb,
    testMeasureReal,
    testMeasurePair,
    testOther
    ]

-- In Maple, should 'evaluate' to "\c -> 1/2*c(Unit)"
t1 :: (Mochastic repr) => repr (Measure ())
t1 = uniform 0 1 `bind` \x -> factor (unsafeProb x)

t2 :: Mochastic repr => repr (Measure Prob)
t2 = beta 1 1

t3 :: Mochastic repr => repr (Measure Real)
t3 = normal 0 10

t4 :: Mochastic repr => repr (Measure (Prob, Bool))
t4 = beta 1 1 `bind` \bias -> bern bias `bind` \coin -> dirac (pair bias coin)

-- t5 is "the same" as t1.
t5 :: Mochastic repr => repr (Measure ())
t5 = factor (1/2) `bind_` dirac unit

t6 :: Mochastic repr => repr (Measure Real)
t6 = dirac 5

t7,t7',t7n,t7n' :: Mochastic repr => repr (Measure Real)
t7   = uniform 0 1 `bind` \x -> factor (unsafeProb (x+1)) `bind_` dirac (x*x)
t7'  = uniform 0 1 `bind` \x -> superpose [(unsafeProb x + 1, dirac (x*x))]
t7n  = uniform (-1) 0 `bind` \x -> factor (unsafeProb (x+1)) `bind_` dirac (x*x)
t7n' = uniform (-1) 0 `bind` \x -> superpose [(unsafeProb (x + 1), dirac (x*x))]

-- For sampling efficiency (to keep importance weights at or close to 1),
-- t8 below should read back to uses of "normal", not uses of "lebesgue"
-- then "factor".  (For exact roundtripping, Maple "attributes" might help.)
t8 :: Mochastic repr => repr (Measure (Real, Real))
t8 = normal 0 10 `bind` \x -> normal x 20 `bind` \y -> dirac (pair x y)

t9 :: Mochastic repr => repr (Measure Real)
t9 = lebesgue `bind` \x -> factor (if_ (and_ [less 3 x, less x 7]) (1/2) 0) `bind_` dirac x

t10 :: Mochastic repr => repr (Measure ())
t10 = factor 0

t11 :: Mochastic repr => repr (Measure ())
t11 = factor 1

t12 :: Mochastic repr => repr (Measure ())
t12 = factor 2

t13,t13' :: Mochastic repr => repr (Measure Real)
t13 = bern (3/5) `bind` \b -> dirac (if_ b 37 42)
t13' = superpose [(3/5, dirac 37), (2/5, dirac 42)]

t14,t14' :: Mochastic repr => repr (Measure Real)
t14 = bern (3/5) `bind` \b ->
      if_ b t13 (bern (2/7) `bind` \b' ->
                 if_ b' (uniform 10 12) (uniform 14 16))
t14' = superpose [(4/35, uniform 10 12),
                  (9/25, dirac 37),
                  (2/7, uniform 14 16),
                  (6/25, dirac 42)]

t20 :: (Lambda repr, Mochastic repr) => repr (Prob -> Measure ())
t20 = lam (\y -> uniform 0 1 `bind` \x -> factor (unsafeProb x * y))

t21 :: (Mochastic repr, Integrate repr, Lambda repr) =>
       repr (Real -> Measure Real)
t21 = mcmc (`normal` 1) (normal 0 5)

t22 :: Mochastic repr => repr (Measure ())
t22 = bern (1/2) `bind_` dirac unit

-- was called bayesNet in Nov.06 msg by Ken for exact inference
t23, t23' :: Mochastic repr => repr (Measure (Bool, Bool))
t23 = bern (1/2) `bind` \a ->
               bern (if_ a (9/10) (1/10)) `bind` \b ->
               bern (if_ a (9/10) (1/10)) `bind` \c ->
               dirac (pair b c)
t23' = superpose [(41/100, dirac (pair false false)),
                  ( 9/100, dirac (pair false  true)),
                  ( 9/100, dirac (pair  true false)),
                  (41/100, dirac (pair  true  true))]


t24,t24' :: (Mochastic repr, Lambda repr) => repr (Prob -> Measure ())
t24 = lam (\x ->
      uniform 0 1 `bind` \y ->
      uniform 0 1 `bind` \z ->
      factor (x * exp_ (cos y) * unsafeProb z))
t24' = lam (\x ->
      uniform 0 1 `bind` \y ->
      factor (x * exp_ (cos y) * (1/2)))

t25,t25' :: (Mochastic repr, Lambda repr) => repr (Prob -> Real -> Measure ())
t25 = lam (\x -> lam (\y ->
    uniform 0 1 `bind` \z ->
    factor (x * exp_ (cos y) * unsafeProb z)))
t25' = lam (\x -> lam (\y ->
    factor (x * exp_ (cos y) * (1/2))))

t26 :: (Base repr, Lambda repr, Integrate repr) => repr Prob
t26 = unExpect t1 `app` lam (const 1)

t27 :: (Mochastic repr, Lambda repr) => [repr (Real -> Measure Real)]
t27 = map (\d -> lam (d unit)) $ runDisintegrate
  (\env -> ununit env $
    normal 0 1 `bind` \x ->
    normal x 1 `bind` \y ->
    dirac (pair y x))
t27' :: (Mochastic repr, Lambda repr) => repr (Real -> Measure Real)
t27' = lam (\y ->
  superpose [( exp_ (y * y * ((-1)/4)) * recip (sqrt_ pi_) * (1/2)
             , normal (y/2) (recip (sqrt_ 2)) )])

t28 :: Mochastic repr => repr (Measure Real)
t28 = uniform 0 1

t29 :: Mochastic repr => repr (Measure Real)
t29 = uniform 0 1 `bind` \x -> dirac (exp x)

t30 :: Mochastic repr => repr (Measure Prob)
t30 = uniform 0 1 `bind` \x -> dirac (exp_ x)

t31 :: Mochastic repr => repr (Measure Real)
t31 = uniform (-1) 1

t32 :: Mochastic repr => repr (Measure Real)
t32 = uniform (-1) 1 `bind` \x -> dirac (exp x)

t33 :: Mochastic repr => repr (Measure Prob)
t33 = uniform (-1) 1 `bind` \x -> dirac (exp_ x)

t34 :: Mochastic repr => repr (Measure Prob)
t34 = dirac (if_ (less (2 `asTypeOf` log_ 1) 4) 3 5)

t35 :: (Lambda repr, Mochastic repr) => repr (Real -> Measure Prob)
t35 = lam (\x -> dirac (if_ (less (x `asTypeOf` log_ 1) 4) 3 5))

t36 :: (Lambda repr, Mochastic repr) => repr (Real -> Measure Real)
t36 = lam (dirac . sqrt)

t37 :: (Lambda repr, Mochastic repr) => repr (Real -> Measure Real)
t37 = lam (dirac . recip)

t38 :: (Lambda repr, Mochastic repr) => repr (Prob -> Measure Prob)
t38 = lam (dirac . recip)

t39 :: (Lambda repr, Mochastic repr) => repr (Real -> Measure Real)
t39 = lam (dirac . log)

t40 :: (Lambda repr, Mochastic repr) => repr (Prob -> Measure Real)
t40 = lam (dirac . log_)

t41 :: (Lambda repr, Integrate repr, Mochastic repr) => repr (Measure ((Prob -> Prob) -> Prob))
t41 = dirac $ (unExpect (uniform 0 2 `bind` dirac . unsafeProb))

t42 :: (Lambda repr, Integrate repr, Mochastic repr) => repr (Measure Prob)
t42 = dirac $ (unExpect (uniform 0 2 `bind` dirac . unsafeProb) `app` lam id)

priorAsProposal :: Mochastic repr => repr (Measure (a,b)) -> repr (a,b) -> repr (Measure (a,b))
priorAsProposal p x = bern (1/2) `bind` \c ->
                      p `bind` \x' ->
                      dirac (if_ c
                             (pair (fst_ x ) (snd_ x'))
                             (pair (fst_ x') (snd_ x )))   

gibbsProposal :: (Order_ a, Expect' a ~ a,
                  Mochastic repr, Integrate repr, Lambda repr) =>
                 Disintegrate (Measure (a,b)) ->
                 repr a -> repr (Measure b)
gibbsProposal p x = q x `bind` dirac
  where d:_ = disintegrations (const p)
        q x = normalize (\lift -> case d of Disintegration f -> f unit (lift x))

testGibbsProp1 :: (Lambda repr, Mochastic repr, Integrate repr) =>
                  repr (Real -> Measure Real)
testGibbsProp1 = lam (gibbsProposal norm)

testGibbsProp2 :: (Lambda repr, Mochastic repr, Integrate repr) =>
                  repr (Real -> Measure Real)
testGibbsProp2 = lam (gibbsProposal flipped_norm)

mcmc :: (Mochastic repr, Integrate repr, Lambda repr,
         a ~ Expect' a, Order_ a) =>
        (forall repr'. (Mochastic repr') => repr' a -> repr' (Measure a)) ->
        (forall repr'. (Mochastic repr') => repr' (Measure a)) ->
        repr (a -> Measure a)
mcmc q p =
  let_ (lam (d unit)) $ \mu ->
  lam $ \x ->
    q x `bind` \x' ->
    let_ (min_ 1 (mu `app` pair x' x / mu `app` pair x x')) $ \ratio ->
    bern ratio `bind` \accept ->
    dirac (if_ accept x' x)
  where d:_ = density (\dummy -> ununit dummy $
                       p `bind` \x -> q x `bind` \y -> dirac (pair x y))

testPriorProp :: (Integrate repr, Mochastic repr, Lambda repr) =>
                 repr ((Real, Real) -> Measure (Real, Real))
testPriorProp = mcmc (priorAsProposal norm) norm

runPriorProg :: IO (Maybe ((Double,Double), LF.LogFloat))
runPriorProg = do
   g <- MWC.create
   unSample (app testPriorProp (pair 1 1)) 1 g

norm :: Mochastic repr => repr (Measure (Real, Real))
norm = normal 0 1 `bind` \x ->
       normal x 1 `bind` \y ->
       dirac (pair x y)

flipped_norm :: Mochastic repr => repr (Measure (Real, Real))
flipped_norm = normal 0 1 `bind` \x ->
               normal x 1 `bind` \y ->
               dirac (pair y x)

testMcmc :: IO ()
testMcmc = do
    let s = runPrettyPrint (mcmc (`normal` 1) (normal 0 5))
    assertResult $ show s

-- pull out some of the intermediate expressions for independent study
expr1 :: (Lambda repr, Mochastic repr) => repr (Real -> Prob)
expr1 =  (lam $ \x0 ->
          (lam $ \x1 ->
           lam $ \x2 ->
           lam $ \x3 ->
           (lam $ \x4 ->
            0
            + 1
              * (lam $ \x5 ->
                 (lam $ \x6 ->
                  0
                  + exp_ (-(x2 - 0) * (x2 - 0) / fromProb (2 * exp_ (log_ 5 * 2)))
                    / 5
                    / exp_ (log_ (2 * pi_) * (1 / 2))
                    * (lam $ \x7 -> x7 `app` unit) `app` x6)
                 `app` (lam $ \x6 ->
                        (lam $ \x7 ->
                         (lam $ \x8 -> x8 `app` x2)
                         `app` (lam $ \x8 ->
                                (lam $ \x9 ->
                                 (lam $ \x10 -> x10 `app` unit)
                                 `app` (lam $ \x10 ->
                                        (lam $ \x11 ->
                                         (lam $ \x12 -> x12 `app` x2)
                                         `app` (lam $ \x12 ->
                                                (lam $ \x13 -> x13 `app` pair x2 x10) `app` x11))
                                        `app` x9))
                                `app` x7))
                        `app` x5))
                `app` x4)
           `app` (lam $ \x4 ->
                  (lam $ \x5 -> x5 `app` (x4 `unpair` \x6 x7 -> x7)) `app` x3))
          `app` unit
          `app` x0
          `app` (lam $ \x1 -> 1))

expr2 :: (Mochastic repr, Lambda repr) => repr (Real -> Real -> Prob)
expr2 = (lam $ \x1 ->
          lam $ \x2 ->
          (lam $ \x3 ->
           lam $ \x4 ->
           lam $ \x5 ->
           (lam $ \x6 ->
            0
            + 1
              * (lam $ \x7 ->
                 (lam $ \x8 ->
                  0
                  + exp_ (-(x4 - x3) * (x4 - x3) / fromProb (2 * exp_ (log_ 1 * 2)))
                    / 1
                    / exp_ (log_ (2 * pi_) * (1 / 2))
                    * (lam $ \x9 -> x9 `app` unit) `app` x8)
                 `app` (lam $ \x8 ->
                        (lam $ \x9 ->
                         (lam $ \x10 -> x10 `app` x4)
                         `app` (lam $ \x10 ->
                                (lam $ \x11 ->
                                 (lam $ \x12 -> x12 `app` unit)
                                 `app` (lam $ \x12 ->
                                        (lam $ \x13 ->
                                         (lam $ \x14 -> x14 `app` x4)
                                         `app` (lam $ \x14 ->
                                                (lam $ \x15 -> x15 `app` pair x4 x12) `app` x13))
                                        `app` x11))
                                `app` x9))
                        `app` x7))
                `app` x6)
           `app` (lam $ \x6 ->
                  (lam $ \x7 -> x7 `app` (x6 `unpair` \x8 x9 -> x9)) `app` x5))
          `app` x1
          `app` x2
          `app` (lam $ \x3 -> 1))

-- the one we need in testKernel
expr3 :: (Mochastic repr, Lambda repr) => repr (d -> Prob) -> repr (d -> d -> Prob) -> repr d -> repr d -> repr Prob
expr3 x0 x1 x2 x3 = (if_ (1
                    `less` x0 `app` x3 / x1 `app` x2 `app` x3 * x1 `app` x3 `app` x2
                           / x0 `app` x2)
                   1
                   (x0 `app` x3 / x1 `app` x2 `app` x3 * x1 `app` x3 `app` x2
                    / x0 `app` x2))

-- this is expr3 that we can send to Maple
expr4 :: (Lambda repr, Mochastic repr) => repr ((d -> Prob) -> (d -> d -> Prob) -> d -> d -> Prob)
expr4 = lam (\x0 -> lam (\x1 -> lam (\x2 -> lam (\x3 -> expr3 x0 x1 x2 x3))))

-- testKernel :: Sample IO (Real -> Measure Real)
testKernel :: (Lambda repr, Mochastic repr) => repr (Real -> Measure Real)
testKernel =
-- Below is the output of testMcmc as of 2014-11-05
    let_ expr1 $ \x0 ->
    let_ expr2 $ \x1 ->
    lam $ \x2 ->
    normal x2 1 `bind` \x3 ->
    let_ (expr3 x0 x1 x2 x3) $ \x4 ->
    categorical [(x4, inl unit), (1 - x4, inr unit)] `bind` \x5 ->
    dirac (uneither x5 (\x6 -> x3) (\x6 -> x2))

-- this should be equivalent to the above
testKernel2 :: (Lambda repr, Mochastic repr) => repr (Real -> Measure Real)
testKernel2 =
  lam $ \x2 ->
  normal x2 1 `bind` \x3 ->
  let_ (if_ (1 `less` exp_(-1/50*(x3-x2)*(x3+x2)))
            1
            (exp_(-1/50*(x3-x2)*(x3+x2)))) $ \x4 ->
 categorical [(x4, x3), (1 - x4, x2)]
