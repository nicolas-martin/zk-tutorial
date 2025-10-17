const { buildPoseidon } = require("circomlibjs");

async function computeHashes() {
	console.log("🔐 Computing Poseidon hashes for test inputs...\n");

	const poseidon = await buildPoseidon();
	const F = poseidon.F;

	// For commitment circuit
	console.log("=== Commitment Circuit ===");
	const secret = 123456789n;
	const nullifier = 987654321n;
	const amount = 1000000000n;

	const commitment = F.toObject(poseidon([secret, amount]));
	const nullifierHash = F.toObject(poseidon([nullifier, secret]));

	console.log("Input secret:", secret.toString());
	console.log("Input amount:", amount.toString());
	console.log("Expected commitment:", commitment.toString());
	console.log("Expected nullifierHash:", nullifierHash.toString());

	// For private transfer circuit
	console.log("\n=== Private Transfer Circuit ===");
	const inSecret = 999999n;
	const inAmount = 1000n;
	const outSecret1 = 111111n;
	const outSecret2 = 222222n;
	const outAmount1 = 700n;
	const outAmount2 = 300n;

	const inputCommitment = F.toObject(poseidon([inSecret, inAmount]));
	const outputCommitment1 = F.toObject(poseidon([outSecret1, outAmount1]));
	const outputCommitment2 = F.toObject(poseidon([outSecret2, outAmount2]));
	const transferNullifier = F.toObject(poseidon([inSecret, inSecret]));

	console.log("Input commitment:", inputCommitment.toString());
	console.log("Expected output1:", outputCommitment1.toString());
	console.log("Expected output2:", outputCommitment2.toString());
	console.log("Expected nullifier:", transferNullifier.toString());
	console.log("Public amount (change):", (outAmount1 + outAmount2 - inAmount).toString());

	// For Merkle proof
	console.log("\n=== Merkle Tree Example ===");
	const leaves = [100n, 200n, 300n, 400n];
	const hashedLeaves = leaves.map(l => F.toObject(poseidon([l])));

	console.log("Leaf values:", leaves.map(l => l.toString()));
	console.log("Hashed leaves:", hashedLeaves.map(h => h.toString()));

	// Build a simple Merkle tree
	const level1 = [];
	for (let i = 0; i < hashedLeaves.length; i += 2) {
		const hash = F.toObject(poseidon([
			BigInt(hashedLeaves[i]),
			BigInt(hashedLeaves[i + 1] || hashedLeaves[i])
		]));
		level1.push(hash);
	}

	const root = F.toObject(poseidon([BigInt(level1[0]), BigInt(level1[1])]));
	console.log("Merkle root:", root.toString());

	// Generate transfer input file
	const transferInput = {
		inSecret: inSecret.toString(),
		inAmount: inAmount.toString(),
		outSecret1: outSecret1.toString(),
		outSecret2: outSecret2.toString(),
		outAmount1: outAmount1.toString(),
		outAmount2: outAmount2.toString(),
		inputCommitment: inputCommitment.toString()
	};

	console.log("\n=== Generated transfer_input.json ===");
	console.log(JSON.stringify(transferInput, null, 2));

	// Save the transfer input
	const fs = require('fs');
	fs.writeFileSync('inputs/transfer_input.json', JSON.stringify(transferInput, null, 2));
	console.log("\n✅ Saved to inputs/transfer_input.json");
}

computeHashes().catch(console.error);
