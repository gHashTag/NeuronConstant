# SPDX-License-Identifier: Apache-2.0
# Author: Dmitrii Vasilev <admin@t27.ai>
# Status: pre-silicon (tape-out target 2026-12-16)
#
# Triad Mining Demo
# 60-second mock mining loop.  Era 0 = 1000 TRI/proof.
# Prints "mined N proofs = N×1000 TRI" at each milestone.

from __future__ import annotations

import hashlib
import os
import time


# ---------------------------------------------------------------------------
# Era configuration
# ---------------------------------------------------------------------------

ERA_0_REWARD = 1000  # TRI per accepted proof in Era 0
MINING_DURATION_S = 60
REPORT_INTERVAL_S = 5


# ---------------------------------------------------------------------------
# Minimal mock miner
# ---------------------------------------------------------------------------

class MockMiner:
    """Software mock of Trinity TRIAD proof-of-work miner."""

    def __init__(self, era_reward: int = ERA_0_REWARD) -> None:
        self.era_reward = era_reward
        self.proofs_mined = 0
        print(f"[trinity-sdk] MockMiner initialised — Era 0 reward: {era_reward} TRI/proof")

    def mine_one(self) -> bytes:
        """Simulate generating a single ZK proof (returns mock proof digest)."""
        nonce = os.urandom(8)
        return hashlib.sha256(b"trinity-triad-v1:" + nonce).digest()

    @property
    def total_tri(self) -> int:
        return self.proofs_mined * self.era_reward


# ---------------------------------------------------------------------------
# Demo entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    miner = MockMiner()
    start = time.monotonic()
    next_report = start + REPORT_INTERVAL_S
    end = start + MINING_DURATION_S

    try:
        while time.monotonic() < end:
            _proof = miner.mine_one()
            miner.proofs_mined += 1

            now = time.monotonic()
            if now >= next_report:
                elapsed = int(now - start)
                print(
                    f"[{elapsed:05d}s] mined {miner.proofs_mined} proofs"
                    f" = {miner.total_tri} TRI"
                )
                next_report += REPORT_INTERVAL_S

            # Throttle to ~1 proof / REPORT_INTERVAL_S to match realistic output
            time.sleep(REPORT_INTERVAL_S / 1.0 if miner.proofs_mined == 0
                        else REPORT_INTERVAL_S - 0.001)

    except KeyboardInterrupt:
        print("\nStopped by user.")

    print(
        f"Mining complete. Total: {miner.proofs_mined} proofs"
        f" = {miner.total_tri} TRI"
    )


if __name__ == "__main__":
    main()
