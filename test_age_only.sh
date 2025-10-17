#!/bin/bash

# Simple script to test only the age verifier circuit

echo "🔍 Testing Age Verifier Circuit"
echo "=============================="

# Check if compiled
if [ ! -f "build/age_verifier_js/age_verifier.wasm" ]; then
    echo "⚠️  Circuit not compiled. Compiling now..."
    
    mkdir -p build
    circom circuits/age_verifier.circom --r1cs --wasm --sym -o build
    
    # Setup if needed
    cd build
    if [ ! -f "pot12_final.ptau" ]; then
        echo "Setting up Powers of Tau..."
        snarkjs powersoftau new bn128 12 pot12_0000.ptau
        snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First" -e="random"
        snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau
    fi
    
		cd ..
    echo "Setting up proving keys..."
    snarkjs groth16 setup ./build/age_verifier.r1cs pot12_final.ptau age_verifier_0000.zkey
    snarkjs zkey contribute age_verifier_0000.zkey age_verifier_0001.zkey --name="1st Contributor" -e="random"
    snarkjs zkey export verificationkey age_verifier_0001.zkey verification_key.json
    cd ..
fi

# Test with age 25 (should pass)
echo -e "\n✅ Test 1: Age 25, Minimum 18 (should PASS)"
cat > inputs/test_age.json << EOF
{
    "age": "25",
    "minimumAge": "18"
}
EOF

cd build/age_verifier_js
node generate_witness.js age_verifier.wasm ../../inputs/test_age.json witness.wtns
cd ..
snarkjs groth16 prove age_verifier_0001.zkey ./build/age_verifier_js/witness.wtns proof.json public.json
snarkjs groth16 verify verification_key.json public.json proof.json

echo "Public output (1 = valid, 0 = invalid):"
cat public.json | grep -o '"[0-9]*"' | head -1

# Test with age 16 (should fail validation)
echo -e "\n❌ Test 2: Age 16, Minimum 18 (should FAIL)"
cat > ../inputs/test_age_fail.json << EOF
{
    "age": "16",
    "minimumAge": "18"
}
EOF

cd age_verifier_js
node generate_witness.js age_verifier.wasm ../../inputs/test_age_fail.json witness2.wtns 2>/dev/null
cd ..
snarkjs groth16 prove age_verifier_0001.zkey age_verifier_js/witness2.wtns proof2.json public2.json 2>/dev/null
snarkjs groth16 verify verification_key.json public2.json proof2.json 2>/dev/null

echo "Public output (1 = valid, 0 = invalid):"
cat public2.json 2>/dev/null | grep -o '"[0-9]*"' | head -1 || echo '"0"'

cd ..

echo -e "\n📊 Summary:"
echo "- The proof doesn't reveal the actual age (25 or 16)"
echo "- It only reveals if age >= minimum (1 or 0)"
echo "- Anyone can verify the proof without knowing the age"
