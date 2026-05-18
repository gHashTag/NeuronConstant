# SPDX-License-Identifier: Apache-2.0
# Author: Dmitrii Vasilev <admin@t27.ai>
# Status: pre-silicon (tape-out target 2026-12-16)
#
# Attested Validator Demo
# Mock Bittensor BIT-0011 validator using trinity_bittensor.ConvictionAttestor.

from __future__ import annotations

import hashlib
import dataclasses


# ---------------------------------------------------------------------------
# Minimal mock of trinity-bittensor ConvictionAttestor
# ---------------------------------------------------------------------------

ANCHOR = 0x47C0  # Trinity chip identity anchor


@dataclasses.dataclass
class AttestationResult:
    job_id: int
    status: str
    score: float
    anchor: int
    signature: bytes

    def __str__(self) -> str:
        lines = [
            f"  status   : {self.status}",
            f"  score    : {self.score:.4f}",
            f"  anchor   : 0x{self.anchor:04X}",
            f"  signature: {self.signature.hex()}",
        ]
        return "\n".join(lines)


class ConvictionAttestorMock:
    """Software mock of trinity_bittensor.ConvictionAttestor (BIT-0011)."""

    def __init__(self) -> None:
        print("[trinity-bittensor] ConvictionAttestor initialised (mock, BIT-0011)")

    def attest(self, job_id: int) -> AttestationResult:
        import os

        # Deterministic-ish score from job_id, plus noise
        raw = hashlib.sha256(
            f"job:{job_id}:anchor:{ANCHOR}".encode() + os.urandom(4)
        ).digest()
        score = 0.85 + (raw[0] / 255.0) * 0.15  # score in [0.85, 1.00]
        signature = hashlib.sha256(raw).digest()
        return AttestationResult(
            job_id=job_id,
            status="ATTESTED",
            score=round(score, 4),
            anchor=ANCHOR,
            signature=signature,
        )

    def submit(self, result: AttestationResult) -> None:
        # Mock submission to Bittensor subnet validator
        print("Validator response submitted (mock).")


# ---------------------------------------------------------------------------
# Demo entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    attestor = ConvictionAttestorMock()

    job_id = 42
    print(f"Attesting job {job_id}...")

    result = attestor.attest(job_id)
    print(f"Attestation result for job {job_id}:")
    print(result)

    attestor.submit(result)


if __name__ == "__main__":
    main()
