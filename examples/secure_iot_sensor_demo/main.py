# SPDX-License-Identifier: Apache-2.0
# Author: Dmitrii Vasilev <admin@t27.ai>
# Status: pre-silicon (tape-out target 2026-12-16)
#
# Secure IoT Sensor Demo
# PUF-based sensor identity (anchor 0x47C0), sign reading, verify on host.

from __future__ import annotations

import hashlib
import hmac
import json


# ---------------------------------------------------------------------------
# Minimal mocks of trinity-sdk PUF and sensor utilities
# ---------------------------------------------------------------------------

ANCHOR = 0x47C0  # Trinity chip identity anchor
_PUF_SEED = b"trinity-puf-seed-v1"  # Deterministic for demo; real PUF is hardware


class MockPUF:
    """Software mock of Trinity on-chip PUF."""

    def __init__(self) -> None:
        print(f"[trinity-sdk] MockPUF initialised — anchor 0x{ANCHOR:04X}")
        self._identity = hashlib.sha256(_PUF_SEED + ANCHOR.to_bytes(2, "big")).digest()

    @property
    def identity(self) -> bytes:
        return self._identity

    def sign(self, data: bytes) -> bytes:
        """HMAC-SHA256 over data, keyed by PUF identity (mock)."""
        return hmac.new(self._identity, data, hashlib.sha256).digest()

    def verify(self, data: bytes, signature: bytes) -> bool:
        expected = self.sign(data)
        return hmac.compare_digest(expected, signature)


def read_mock_sensor() -> dict:
    """Return a fake temperature/humidity reading."""
    return {"temperature_c": 23.4, "humidity_pct": 61.2}


# ---------------------------------------------------------------------------
# Demo entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    puf = MockPUF()
    print(f"PUF identity: {puf.identity.hex()}")

    reading = read_mock_sensor()
    print(f"Sensor reading: {reading}")

    payload = json.dumps(reading, sort_keys=True).encode()
    signature = puf.sign(payload)
    print(f"Signature: {signature.hex()}")

    ok = puf.verify(payload, signature)
    print(f"Host verification: {'PASS' if ok else 'FAIL'}")
    print(f"Device identity bound to anchor 0x{ANCHOR:04X}.")


if __name__ == "__main__":
    main()
