#!/bin/bash

# Build script for all circuits
# This compiles all circuits and sets up the proving/verification keys

echo "🔨 ZK Circuit Builder"
echo "===================="

# Create build directory
mkdir -p build

# Check if circom is installed
if ! command -v circom &> /dev/null; then
    echo "❌ Circom not found. Please install it first:"
    echo "   brew install circom"
    echo "   or see: https://docs.circom.io/getting-started/installation/"
    exit 1
fi

# Check if snarkjs is installed
if ! command -v snarkjs &> /dev/null; then
    echo "❌ SnarkJS not found. Installing..."
    npm install -g snarkjs
fi

echo -e "\n📦 Installing npm dependencies..."
npm install

echo -e "\n🔧 Compiling circuits..."

# Compile Age Verifier
echo -e "\n1️⃣ Compiling Age Verifier..."
circom circuits/age_verifier.circom --r1cs --wasm --sym -o build
if [ $? -eq 0 ]; then
    echo "✅ Age Verifier compiled"
else
    echo "❌ Failed to compile Age Verifier"
fi

# Compile Commitment
echo -e "\n2️⃣ Compiling Commitment Circuit..."
circom circuits/commitment.circom --r1cs --wasm --sym -o build
if [ $? -eq 0 ]; then
    echo "✅ Commitment Circuit compiled"
else
    echo "❌ Failed to compile Commitment Circuit"
fi

# Compile Merkle Proof
echo -e "\n3️⃣ Compiling Merkle Proof..."
circom circuits/merkle_proof.circom --r1cs --wasm --sym -o build
if [ $? -eq 0 ]; then
    echo "✅ Merkle Proof compiled"
else
    echo "❌ Failed to compile Merkle Proof"
fi

# Compile Private Transfer
echo -e "\n4️⃣ Compiling Private Transfer..."
circom circuits/private_transfer.circom --r1cs --wasm --sym -o build
if [ $? -eq 0 ]; then
    echo "✅ Private Transfer compiled"
else
    echo "❌ Failed to compile Private Transfer"
fi

echo -e "\n🔑 Setting up trusted setup (Powers of Tau)..."

# Check if Powers of Tau already exists
if [ ! -f "build/pot12_final.ptau" ]; then
    echo "Creating new Powers of Tau ceremony..."
    cd build
    
    # Start ceremony
    snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
    
    # Contribute (in production, multiple parties do this)
    snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v
    
    # Prepare phase 2
    snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
    
    cd ..
    echo "✅ Powers of Tau ceremony complete"
else
    echo "✅ Using existing Powers of Tau"
fi

echo -e "\n🔐 Generating proving and verification keys..."

# Setup keys for each circuit
circuits=("age_verifier" "commitment" "merkle_proof" "private_transfer")

for circuit in "${circuits[@]}"; do
    echo -e "\n  Setting up $circuit..."
    cd build
    
    if [ -f "${circuit}.r1cs" ]; then
        # Generate zkey
        snarkjs groth16 setup ${circuit}.r1cs pot12_final.ptau ${circuit}_0000.zkey
        
        # Contribute to phase 2
        snarkjs zkey contribute ${circuit}_0000.zkey ${circuit}_0001.zkey --name="1st Contributor" -v
        
        # Export verification key
        snarkjs zkey export verificationkey ${circuit}_0001.zkey ${circuit}_verification_key.json
        
        echo "  ✅ Keys generated for $circuit"
    else
        echo "  ⚠️  Skipping $circuit (no r1cs file)"
    fi
    
    cd ..
done

echo -e "\n📊 Computing test hashes..."
node scripts/compute_hash.js

echo -e "\n✨ Build complete!"
echo "   Run ./scripts/test_all.sh to test the circuits"