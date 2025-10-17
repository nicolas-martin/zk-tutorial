pragma circom 2.0.0;

// Circuit to prove age is above a threshold without revealing the actual age
template AgeVerifier() {
    // Private input - the actual age (kept secret)
    signal input age;
    
    // Public inputs
    signal input minimumAge;  // The threshold (e.g., 18)
    signal output isValid;    // 1 if age >= minimumAge, 0 otherwise
    
    signal diff;
    diff <== age - minimumAge;
    
    // For this tutorial, we'll use a simplified check
    // In production, you'd use proper comparison circuits from circomlib
    component check = IsNonNegative();
    check.in <== diff;
    
    isValid <== check.out;
}

// Simplified template to check if a number is non-negative
// WARNING: This is simplified for tutorial purposes
template IsNonNegative() {
    signal input in;
    signal output out;
    
    // Use a simple constraint for small positive numbers
    // This assigns 1 if in >= 0, else 0
    out <-- (in >= 0) ? 1 : 0;
    
    // Ensure output is binary (0 or 1)
    out * (1 - out) === 0;
    
    // Additional constraint to link input and output
    // This is simplified - production circuits need range proofs
    signal inAbs;
    signal isZero;
    
    isZero <-- (in == 0) ? 1 : 0;
    isZero * (1 - isZero) === 0;
    
    inAbs <-- (in >= 0) ? in : -in;
    
    // If out is 1, then either in is 0 or in is positive
    // If out is 0, then in must be negative
    (1 - out) * in === 0;
}

component main = AgeVerifier();
