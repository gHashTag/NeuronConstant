# PI Review Notes — Trinity Network Launch Thread
**For:** Dmitrii Vasilev (admin@t27.ai)  
**Re:** TWITTER_LAUNCH_THREAD.md  
**Status:** Internal review companion. Not for posting.

---

## 1. Optimal Post Timing (UTC)

Best windows for crypto + AI Twitter overlap:

| Window | UTC | Rationale |
|--------|-----|-----------|
| Primary | Tuesday–Thursday, 13:00–15:00 UTC | US East Coast morning + EU afternoon peak |
| Secondary | Monday 08:00–09:00 UTC | EU business-day open, pre-NY session energy |
| Avoid | Friday 17:00+ UTC | Weekend bleed, lower engagement |
| Avoid | Saturday/Sunday any | Low reply velocity hurts algorithmic reach |

Recommended: **Tuesday or Wednesday, 13:30 UTC** for maximum US/EU/RU reach.

---

## 2. Pre-Post Checklist

### Links
- [ ] Replace `[WHITEPAPER_LINK]` with live URL (t27.ai/whitepaper or IPFS hash)
- [ ] Replace `[GITHUB_LINK]` with direct repo URL (e.g. github.com/t27ai/trinity)
- [ ] Replace `[DOI_LINK 10.5281/zenodo.19227877]` with `https://doi.org/10.5281/zenodo.19227877`
- [ ] Confirm all URLs resolve before posting

### Accuracy & Claims
- [ ] Confirm tape-out submission date is today and correct
- [ ] Confirm "projected, pending tape-out 2026-12-16" wording is retained — do NOT remove qualifier
- [ ] Confirm "~1 GOPS @ ~50 MHz @ ~1W" are current projected figures
- [ ] Confirm Era 0 reward is exactly 1,000 TRI/proof
- [ ] Confirm halving count is 9 and final coin year ~2066
- [ ] Confirm B9 BittensorSubnetAttest contract address is NOT included (see risk section)
- [ ] Verify 3^27 = 7,625,597,484,987 (it does: already verified)

### Legal & Compliance
- [ ] No forward-looking guarantee language (use "projected", "target", "planned")
- [ ] No investment language ("will 100x", "guaranteed return") — none present, keep it that way
- [ ] Russian tweet reviewed for accuracy by native speaker if possible

### Formatting
- [ ] Count each tweet manually in Twitter composer (not a text editor) — emoji characters vary
- [ ] Tweet 9 flagged ~294 chars — trim before posting, suggested cut: remove "→ Anduril defence-grade edge inference trials" or shorten
- [ ] Confirm 🎖️ renders correctly on mobile before posting tweet 1
- [ ] Thread is posted as a single connected thread, not separate tweets

---

## 3. Suggested Follow-Up Tweets (if engagement is high)

Post these individually as the conversation evolves — do not pre-schedule blindly.

**F1 — Technical deep-dive prompt**
> Lots of questions on the TRI-27 kernel. Thread incoming on ternary vs binary MAC efficiency.
> Short answer: 1 trit carries log2(3) ≈ 1.585 bits — ~37% more info per wire.
> #Trinity #TT

**F2 — Chip photo / render (when available)**
> First die renders from SKY26b layout. Phi MAC array on the left, Euler ZK engine right.
> [ATTACH IMAGE]
> Tape-out: 2026-12-16. Clock is running.
> #SKY26b #TT #Trinity

**F3 — Mining economics explainer**
> Q: How profitable is Era 0 mining?
> A: 1,000 TRI/proof. Halves at proof milestones, not calendar time.
> You mine more by generating more valid ZK proofs. Work faster = earn more.
> Full schedule: [WHITEPAPER_LINK]
> #Trinity #FairLaunch

**F4 — Bittensor subnet AMA offer**
> If you run a Bittensor validator and want to test ternary attestation on B9 subnet,
> DM or email admin@t27.ai.
> Early validators get priority onboarding.
> #Bittensor #DePIN #Trinity

**F5 — Russian follow-up**
> Для майнеров и валидаторов из СНГ: мы ищем партнёров.
> Ранние участники получат приоритет при запуске ноды.
> Пишите: admin@t27.ai
> #Trinity #Bittensor

---

## 4. Risk Notes

### Contract Address
**Do NOT tweet or link any smart contract address until a third-party audit is complete.**
A public address without an audit report is an invitation for front-running, impersonation, and social engineering.
Audit first. Address public second.

### Hardware Claims
The "~1 GOPS @ ~50 MHz @ ~1W" figure is a pre-silicon projection.
If any benchmark number changes before tape-out returns, update tweet 7 immediately.
A wrong public benchmark on a scientific project is reputationally worse than silence.

### Partnership Teasers (Tweet 9)
"DARPA-adjacent", "Anduril trials" — only post these if relationships are confirmed and the other party is aware the mention is public.
If any is speculative, remove it from the tweet before posting.

### Impersonation
After posting, monitor for fake accounts mimicking @t27ai or @dmitriivasilev.
Report immediately via X's impersonation flow.

---

*Prepared for PI review only. Dmitrii Vasilev retains full editorial control.*
