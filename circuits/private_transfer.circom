pragma circom 2.0.0;

include "../../scripts/node_modules/circomlib/circuits/poseidon.circom";

// Simplified version of Privacy Cash's transaction circuit
// Shows how to transfer value privately using commitments and nullifiers
template PrivateTransfer() {
    // Private inputs (secrets)
    signal input inSecret;        // Secret proving ownership of input UTXO
    signal input inAmount;        // Amount in the input UTXO
    signal input outSecret1;      // New secret for output UTXO 1
    signal input outSecret2;      // New secret for output UTXO 2
    signal input outAmount1;      // Amount for output UTXO 1
    signal input outAmount2;      // Amount for output UTXO 2
    
    // Public inputs
    signal input inputCommitment;    // The commitment being spent (must be in tree)
    
    // Public outputs
    signal output outputCommitment1; // New commitment 1 (added to tree)
    signal output outputCommitment2; // New commitment 2 (added to tree)
    signal output nullifier;         // Nullifier (prevents double-spending)
    signal output publicAmount;      // Amount deposited/withdrawn (can be 0)
    
    // Step 1: Verify the input commitment
    // This proves we know the secret for the commitment we're spending
    component inputHasher = Poseidon(2);
    inputHasher.inputs[0] <== inSecret;
    inputHasher.inputs[1] <== inAmount;
    
    // Ensure the computed commitment matches the public input
    inputCommitment === inputHasher.out;
    
    // Step 2: Create nullifier to prevent double-spending
    // Hash the secret with itself to create a unique nullifier
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== inSecret;
    nullifierHasher.inputs[1] <== inSecret;
    nullifier <== nullifierHasher.out;
    
    // Step 3: Check amount conservation
    // Input amount + public amount = output amounts
    // publicAmount can be negative (withdrawal) or positive (deposit)
    signal totalOut;
    totalOut <== outAmount1 + outAmount2;
    
    // For deposits: inAmount + publicAmount = totalOut
    // For withdrawals: inAmount = totalOut + |publicAmount|
    // For transfers: inAmount = totalOut (publicAmount = 0)
    publicAmount <== totalOut - inAmount;
    
    // Step 4: Create output commitments
    // These will be added to the Merkle tree
    component outHasher1 = Poseidon(2);
    outHasher1.inputs[0] <== outSecret1;
    outHasher1.inputs[1] <== outAmount1;
    outputCommitment1 <== outHasher1.out;
    
    component outHasher2 = Poseidon(2);
    outHasher2.inputs[0] <== outSecret2;
    outHasher2.inputs[1] <== outAmount2;
    outputCommitment2 <== outHasher2.out;
    
    // This circuit enables:
    // 1. Deposits: publicAmount > 0, inAmount = 0
    // 2. Withdrawals: publicAmount < 0
    // 3. Transfers: publicAmount = 0, split/join UTXOs
}

component main = PrivateTransfer();
