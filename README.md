# ZK Tutorial

A hands-on tutorial for learning zero-knowledge proofs using Circom and SnarkJS.

## Overview

This project demonstrates practical implementations of zero-knowledge proof circuits including age verification, commitments, Merkle tree proofs, and private transfers. Each circuit showcases how to prove statements about data without revealing the underlying information.


## Circuits

### 1. Age Verifier
Proves that someone's age is above a threshold without revealing the actual age.
- Location: `circuits/age_verifier.circom`
- Use case: Privacy-preserving age verification

### 2. Commitment
Creates cryptographic commitments to values that can be revealed later.
- Location: `circuits/commitment.circom`
- Use case: Sealed bid auctions, voting systems

### 3. Merkle Proof
Proves membership in a Merkle tree without revealing other tree elements.
- Location: `circuits/merkle_proof.circom`
- Use case: Privacy-preserving whitelists, asset ownership

### 4. Private Transfer
Enables private value transfers while maintaining transaction validity.
- Location: `circuits/private_transfer.circom`
- Use case: Confidential transactions

### Generating Proofs

1. Prepare your input data in JSON format (see `inputs/` for examples)
2. Generate witness:
```bash
cd build/[circuit_name]_js
node generate_witness.js [circuit_name].wasm ../../inputs/[input_file].json witness.wtns
```

3. Generate proof:
```bash
snarkjs groth16 prove [circuit_name]_0001.zkey witness.wtns proof.json public.json
```

4. Verify proof:
```bash
snarkjs groth16 verify [circuit_name]_verification_key.json public.json proof.json
```

## Visualizations

Open `visualizations/merkle-tree-viz.html` in a browser to interact with a visual representation of Merkle tree proofs.
