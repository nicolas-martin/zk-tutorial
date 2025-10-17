pragma circom 2.0.0;

include "../../scripts/node_modules/circomlib/circuits/poseidon.circom";
include "../../scripts/node_modules/circomlib/circuits/mux1.circom";

// Proves that a leaf exists in a Merkle tree without revealing which leaf
// This is core to Privacy Cash - proving your deposit exists without revealing which one
template MerkleProof(levels) {
    // Private inputs
    signal input leaf;                    // The leaf value (your commitment)
    signal input pathElements[levels];    // Sibling hashes along the path
    signal input pathIndices[levels];     // 0 = left, 1 = right at each level
    
    // Public input
    signal output root;                   // The Merkle root to verify against
    
    component hashers[levels];
    component mux[levels];
    
    signal currentHash[levels + 1];
    currentHash[0] <== leaf;
    
    // Traverse from leaf to root
    for (var i = 0; i < levels; i++) {
        // pathIndices[i] determines if currentHash goes left (0) or right (1)
        mux[i] = Mux1();
        mux[i].c[0] <== currentHash[i];
        mux[i].c[1] <== pathElements[i];
        mux[i].s <== pathIndices[i];
        
        // Hash the pair in correct order
        hashers[i] = Poseidon(2);
        hashers[i].inputs[0] <== mux[i].out[0];  // Left element
        hashers[i].inputs[1] <== mux[i].out[1];  // Right element
        
        currentHash[i + 1] <== hashers[i].out;
    }
    
    // The final hash should be the root
    root <== currentHash[levels];
    
    // This circuit proves:
    // "I know a leaf and a path that hash to this root"
    // Without revealing which leaf or path!
}

// 3 levels = up to 8 leaves (2^3)
component main = MerkleProof(3);
