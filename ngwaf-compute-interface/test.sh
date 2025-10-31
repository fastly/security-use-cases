#!/bin/bash

# Test script for Fastly Compute@Edge NGWAF Interface
# Since tests are compiled to WASM, we verify they compile successfully

set -e

echo "======================================"
echo "Testing NGWAF Compute Interface"
echo "======================================"

echo ""
echo "Step 1: Building project..."
cargo build

echo ""
echo "Step 2: Compiling tests..."
cargo test --no-run

echo ""
echo "======================================"
echo "✓ All tests compiled successfully!"
echo "======================================"
echo ""
echo "Note: Tests are compiled to WASM target (wasm32-wasip1)"
echo "They verify:"
echo "  - Authentication logic (cdn-secret header validation)"
echo "  - Status code mapping (200-499 range handling)"
echo "  - JSON response structure"
echo "  - WAF header formatting"
echo "  - IP address parsing"
echo "  - Error handling patterns"
echo ""
echo "To run in Fastly Compute environment, deploy and test with:"
echo "  fastly compute publish"
echo ""
