{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TemplateHaskell #-}

module Test.Cardano.Api.Typed.CBOR
  ( tests
  ) where

import           Cardano.Prelude

import           Hedgehog (Property)
import           Test.Tasty (TestTree, testGroup)
import           Test.Tasty.Hedgehog (testProperty)
import           Test.Tasty.TH (testGroupGenerator)

import           Cardano.Api

import           Test.Cardano.Api.Typed.Orphans ()
import           Gen.Cardano.Api.Typed
import           Gen.Hedgehog.Roundtrip.CBOR (roundtrip_CBOR)

{- HLINT ignore "Use camelCase" -}

-- TODO: Need to add PaymentExtendedKey roundtrip tests however
-- we can't derive an Eq instance for Crypto.HD.XPrv

test_roundtrip_txbody_CBOR :: [TestTree]
test_roundtrip_txbody_CBOR =
  [ testProperty (show era) $
    roundtrip_CBOR (proxyToAsType Proxy) (genTxBody era)
  | AnyCardanoEra era <- [minBound..]
  ]

test_roundtrip_tx_CBOR :: [TestTree]
test_roundtrip_tx_CBOR =
  [ testProperty (show era) $ roundtrip_CBOR (proxyToAsType Proxy) (genTx era)
  | AnyCardanoEra era <- [minBound..]
  ]

prop_roundtrip_witness_shelley_CBOR :: Property
prop_roundtrip_witness_shelley_CBOR =
  roundtrip_CBOR (AsKeyWitness AsShelleyEra) (genShelleyWitness ShelleyEra)

prop_roundtrip_witness_allegra_CBOR :: Property
prop_roundtrip_witness_allegra_CBOR =
  roundtrip_CBOR (AsKeyWitness AsAllegraEra) (genShelleyWitness AllegraEra)

prop_roundtrip_witness_mary_CBOR :: Property
prop_roundtrip_witness_mary_CBOR =
  roundtrip_CBOR (AsKeyWitness AsMaryEra) (genShelleyWitness MaryEra)

prop_roundtrip_witness_alonzo_CBOR :: Property
prop_roundtrip_witness_alonzo_CBOR =
  roundtrip_CBOR (AsKeyWitness AsAlonzoEra) (genShelleyWitness AlonzoEra)

prop_roundtrip_operational_certificate_CBOR :: Property
prop_roundtrip_operational_certificate_CBOR =
  roundtrip_CBOR AsOperationalCertificate genOperationalCertificate

prop_roundtrip_operational_certificate_issue_counter_CBOR :: Property
prop_roundtrip_operational_certificate_issue_counter_CBOR =
  roundtrip_CBOR AsOperationalCertificateIssueCounter genOperationalCertificateIssueCounter

prop_roundtrip_verification_key_byron_CBOR :: Property
prop_roundtrip_verification_key_byron_CBOR =
  roundtrip_CBOR (AsVerificationKey AsByronKey) (genVerificationKey AsByronKey)

prop_roundtrip_signing_key_byron_CBOR :: Property
prop_roundtrip_signing_key_byron_CBOR =
  roundtrip_CBOR (AsSigningKey AsByronKey) (genSigningKey AsByronKey)

prop_roundtrip_verification_key_payment_CBOR :: Property
prop_roundtrip_verification_key_payment_CBOR =
  roundtrip_CBOR (AsVerificationKey AsPaymentKey) (genVerificationKey AsPaymentKey)

prop_roundtrip_signing_key_payment_CBOR :: Property
prop_roundtrip_signing_key_payment_CBOR =
  roundtrip_CBOR (AsSigningKey AsPaymentKey) (genSigningKey AsPaymentKey)

prop_roundtrip_verification_key_stake_CBOR :: Property
prop_roundtrip_verification_key_stake_CBOR =
  roundtrip_CBOR (AsVerificationKey AsStakeKey) (genVerificationKey AsStakeKey)

prop_roundtrip_signing_key_stake_CBOR :: Property
prop_roundtrip_signing_key_stake_CBOR =
  roundtrip_CBOR (AsSigningKey AsStakeKey) (genSigningKey AsStakeKey)

prop_roundtrip_verification_key_genesis_CBOR :: Property
prop_roundtrip_verification_key_genesis_CBOR =
  roundtrip_CBOR (AsVerificationKey AsGenesisKey) (genVerificationKey AsGenesisKey)

prop_roundtrip_signing_key_genesis_CBOR :: Property
prop_roundtrip_signing_key_genesis_CBOR =
  roundtrip_CBOR (AsSigningKey AsGenesisKey) (genSigningKey AsGenesisKey)

prop_roundtrip_verification_key_genesis_delegate_CBOR :: Property
prop_roundtrip_verification_key_genesis_delegate_CBOR =
  roundtrip_CBOR (AsVerificationKey AsGenesisDelegateKey) (genVerificationKey AsGenesisDelegateKey)

prop_roundtrip_signing_key_genesis_delegate_CBOR :: Property
prop_roundtrip_signing_key_genesis_delegate_CBOR =
  roundtrip_CBOR (AsSigningKey AsGenesisDelegateKey) (genSigningKey AsGenesisDelegateKey)

prop_roundtrip_verification_key_stake_pool_CBOR :: Property
prop_roundtrip_verification_key_stake_pool_CBOR =
  roundtrip_CBOR (AsVerificationKey AsStakePoolKey) (genVerificationKey AsStakePoolKey)

prop_roundtrip_signing_key_stake_pool_CBOR :: Property
prop_roundtrip_signing_key_stake_pool_CBOR =
  roundtrip_CBOR (AsSigningKey AsStakePoolKey) (genSigningKey AsStakePoolKey)

prop_roundtrip_verification_key_vrf_CBOR :: Property
prop_roundtrip_verification_key_vrf_CBOR =
  roundtrip_CBOR (AsVerificationKey AsVrfKey) (genVerificationKey AsVrfKey)

prop_roundtrip_signing_key_vrf_CBOR :: Property
prop_roundtrip_signing_key_vrf_CBOR =
  roundtrip_CBOR (AsSigningKey AsVrfKey) (genSigningKey AsVrfKey)

prop_roundtrip_verification_key_kes_CBOR :: Property
prop_roundtrip_verification_key_kes_CBOR =
  roundtrip_CBOR (AsVerificationKey AsKesKey) (genVerificationKey AsKesKey)

prop_roundtrip_signing_key_kes_CBOR :: Property
prop_roundtrip_signing_key_kes_CBOR =
  roundtrip_CBOR (AsSigningKey AsKesKey) (genSigningKey AsKesKey)

prop_roundtrip_script_SimpleScriptV1_CBOR :: Property
prop_roundtrip_script_SimpleScriptV1_CBOR =
  roundtrip_CBOR (AsScript AsSimpleScriptV1)
                 (genScript (SimpleScriptLanguage SimpleScriptV1))

prop_roundtrip_script_SimpleScriptV2_CBOR :: Property
prop_roundtrip_script_SimpleScriptV2_CBOR =
  roundtrip_CBOR (AsScript AsSimpleScriptV2)
                 (genScript (SimpleScriptLanguage SimpleScriptV2))

prop_roundtrip_script_PlutusScriptV1_CBOR :: Property
prop_roundtrip_script_PlutusScriptV1_CBOR =
  roundtrip_CBOR (AsScript AsPlutusScriptV1)
                 (genScript (PlutusScriptLanguage PlutusScriptV1))

test_roundtrip_UpdateProposal_CBOR :: [TestTree]
test_roundtrip_UpdateProposal_CBOR =
  [ testProperty (show era) $
    roundtrip_CBOR AsUpdateProposal $ genUpdateProposal era
  | AnyCardanoEra era <- [minBound..]
  ]

-- -----------------------------------------------------------------------------

tests :: TestTree
tests = $testGroupGenerator
