pragma circom 2.0.0;

include "../../scripts/node_modules/circomlib/circuits/poseidon.circom";

// This circuit demonstrates the commitment pattern used in Privacy Cash
// It shows how to create commitments and nullifiers from secret data
template CommitmentCircuit() {
    // Private inputs (secrets that prove ownership)
    signal input secret;      // User's secret key
    signal input nullifier;   // Random value for nullifier generation
    signal input amount;      // Amount being committed
    
    // Public outputs
    signal output commitment;     // Public commitment (goes on-chain)
    signal output nullifierHash;  // Nullifier (prevents double-spending)
    
    // Create commitment = Poseidon(secret, amount)
    // This binds the secret to a specific amount
    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== amount;
    commitment <== commitmentHasher.out;
    
    // Create nullifierHash = Poseidon(nullifier, secret)
    // This creates a unique nullifier for this commitment
    // When spending, revealing this nullifier prevents double-spending
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== nullifier;
    nullifierHasher.inputs[1] <== secret;
    nullifierHash <== nullifierHasher.out;
    
    // In Privacy Cash, the commitment is added to the Merkle tree
    // The nullifier is revealed when withdrawing to prevent reuse
}

component main = CommitmentCircuit();
