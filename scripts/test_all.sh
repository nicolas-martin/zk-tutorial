#!/bin/bash

# Test script for all circuits
# This generates proofs and verifies them

echo "🧪 ZK Circuit Tester"
echo "==================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to test a circuit
test_circuit() {
    local circuit_name=$1
    local input_file=$2
    
    echo -e "\n🔍 Testing: $circuit_name"
    echo "   Input: $input_file"
    
    # Check if circuit is compiled
    if [ ! -f "build/${circuit_name}_js/${circuit_name}.wasm" ]; then
        echo -e "${RED}   ❌ Circuit not compiled. Run ./scripts/build_all.sh first${NC}"
        return 1
    fi
    
    # Generate witness
    echo "   Generating witness..."
    cd build/${circuit_name}_js
    node generate_witness.js ${circuit_name}.wasm ../../${input_file} witness.wtns
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}   ❌ Failed to generate witness${NC}"
        cd ../..
        return 1
    fi
    
    cd ../..
    
    # Generate proof
    echo "   Generating proof..."
    cd build
    snarkjs groth16 prove ${circuit_name}_0001.zkey ${circuit_name}_js/witness.wtns proof.json public.json
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}   ❌ Failed to generate proof${NC}"
        cd ..
        return 1
    fi
    
    # Verify proof
    echo "   Verifying proof..."
    snarkjs groth16 verify ${circuit_name}_verification_key.json public.json proof.json
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ Proof verified successfully!${NC}"
        
        # Show public signals
        echo "   Public signals:"
        cat public.json | python3 -m json.tool | grep -A 100 '"' | head -10
        
        # Save proof and public signals
        mv proof.json ${circuit_name}_proof.json
        mv public.json ${circuit_name}_public.json
        echo "   Saved: build/${circuit_name}_proof.json and build/${circuit_name}_public.json"
    else
        echo -e "${RED}   ❌ Proof verification failed${NC}"
        cd ..
        return 1
    fi
    
    cd ..
    return 0
}

# Test each circuit
echo -e "\n====== Test Results ======"

# 1. Age Verifier
test_circuit "age_verifier" "inputs/age_input.json"
age_result=$?

# 2. Commitment Circuit
test_circuit "commitment" "inputs/commitment_input.json"
commitment_result=$?

# 3. Private Transfer
test_circuit "private_transfer" "inputs/transfer_input.json"
transfer_result=$?

# Summary
echo -e "\n====== Summary ======"
if [ $age_result -eq 0 ]; then
    echo -e "${GREEN}✅ Age Verifier: PASSED${NC}"
else
    echo -e "${RED}❌ Age Verifier: FAILED${NC}"
fi

if [ $commitment_result -eq 0 ]; then
    echo -e "${GREEN}✅ Commitment Circuit: PASSED${NC}"
else
    echo -e "${RED}❌ Commitment Circuit: FAILED${NC}"
fi

if [ $transfer_result -eq 0 ]; then
    echo -e "${GREEN}✅ Private Transfer: PASSED${NC}"
else
    echo -e "${RED}❌ Private Transfer: FAILED${NC}"
fi

echo -e "\n💡 Tips:"
echo "   - Check build/*_public.json to see public outputs"
echo "   - Check build/*_proof.json to see the generated proofs"
echo "   - Modify inputs/*.json files to test different scenarios"
echo "   - The proofs reveal nothing about the private inputs!"
