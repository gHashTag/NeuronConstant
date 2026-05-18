# SPDX-License-Identifier: Apache-2.0
# Author: Dmitrii Vasilev <admin@t27.ai>
# Status: pre-silicon (tape-out target 2026-12-16)
#
# PoRep Storage Demo
# Generate a fake 32-byte sector, run mock Filecoin PoRep, print digest.

from __future__ import annotations

import hashlib
import os
import struct


# ---------------------------------------------------------------------------
# Minimal mock of trinity-sdk PoRep accelerator
# ---------------------------------------------------------------------------

class MockPoRep:
    """Software mock of Trinity ternary PoRep pipeline."""

    def __init__(self) -> None:
        print("[trinity-sdk] MockPoRep initialised (pre-silicon simulation)")

    def commit(self, sector_id: int, sector_data: bytes) -> bytes:
        """Compute a mock PoRep sector commitment (SHA-256 stand-in)."""
        header = struct.pack(">Q", sector_id)  # 8-byte big-endian sector ID
        return hashlib.sha256(header + sector_data).digest()

    def verify(self, sector_id: int, sector_data: bytes, digest: bytes) -> bool:
        return self.commit(sector_id, sector_data) == digest


# ---------------------------------------------------------------------------
# Demo entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    porep = MockPoRep()

    sector_id = 1
    # 32-byte fake sector (random each run to simulate unique replica)
    sector_data = os.urandom(32)

    print(f"Sector ID  : 0x{sector_id:016X}")
    print(f"Sector data: {sector_data.hex()}")

    digest = porep.commit(sector_id, sector_data)
    print("PoRep commitment computed.")
    print(f"Sector digest: {digest.hex()}")

    ok = porep.verify(sector_id, sector_data, digest)
    print(f"PoRep: {'VALID' if ok else 'INVALID'} (mock)")


if __name__ == "__main__":
    main()
