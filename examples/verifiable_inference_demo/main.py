# SPDX-License-Identifier: Apache-2.0
# Author: Dmitrii Vasilev <admin@t27.ai>
# Status: pre-silicon (tape-out target 2026-12-16)
#
# Verifiable Inference Demo
# Runs a toy model via trinity-sdk MockBackend, emits a ZK proof, and verifies it.
# Performance target: ~1 GOPS @ ~50 MHz @ ~1 W ternary (projected, pending tape-out 2026-12-16)

from __future__ import annotations

import hashlib
import dataclasses
from typing import Any


# ---------------------------------------------------------------------------
# Minimal mock of trinity-sdk until the real package is published
# ---------------------------------------------------------------------------

ANCHOR = 0x47C0  # Trinity chip identity anchor


@dataclasses.dataclass
class Proof:
    statement: str
    witness_hash: bytes

    @property
    def digest(self) -> bytes:
        payload = f"{self.statement}:{self.witness_hash.hex()}".encode()
        return hashlib.sha256(payload).digest()


class MockBackend:
    """Software simulation of the Trinity ternary inference engine."""

    def __init__(self) -> None:
        print("[trinity-sdk] MockBackend initialised (pre-silicon simulation)")

    def prove_inference(self, model_name: str, input_data: Any = None) -> Proof:
        import os

        witness = hashlib.sha256(
            f"{model_name}:{repr(input_data)}".encode()
        ).digest()
        # Mix in random salt to simulate non-deterministic hardware timing noise
        salt = os.urandom(4)
        witness = hashlib.sha256(witness + salt).digest()
        return Proof(statement=f"inference({model_name})", witness_hash=witness)

    def verify(self, proof: Proof) -> bool:
        # Mock verification: always passes (real ZK circuit check on hardware)
        return len(proof.digest) == 32


# ---------------------------------------------------------------------------
# Demo entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    backend = MockBackend()

    input_shape = (1, 128)
    print(f"Running toy inference with input shape {input_shape}...")

    proof = backend.prove_inference("toy", input_data=input_shape)
    print("Proof generated.")
    print(f"Proof digest: {proof.digest.hex()}")

    ok = backend.verify(proof)
    print(f"Verification: {'PASS' if ok else 'FAIL'}")
    print(f"Anchor: 0x{ANCHOR:04X} (identity confirmed, mock)")


if __name__ == "__main__":
    main()
