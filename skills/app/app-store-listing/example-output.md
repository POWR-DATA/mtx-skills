# Example Output — App Store Listing

## 1. API key setup summary

- **Access:** Requested at Users and Access → Integrations → App Store Connect API → Request Access (approved by email same day)
- **Key created:** p8 downloaded once and stored in a password manager
- **Recorded:** Key ID `XXXXXXXXXX`, Issuer ID `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **For EAS:** registered via `eas credentials --platform ios` → API key option; p8 can now be discarded locally

## 2. Submission-gate checklist

These three fields block "Add for Review" — complete them first:

- [x] **Primary Category** — App Information → Lifestyle
- [x] **Price** — Pricing and Availability → Free
- [x] **Content Rights** — App Information → Content Rights → No third-party content

> The greyed-out "Add for Review" button was caused by Content Rights being unanswered. With all three set, the button becomes available.

## 3. Screenshot spec (Chrome DevTools device emulation)

| Slot | DevTools device | DPR | Output |
|---|---|---|---|
| iPhone 6.5" Display | 414 × 896 | 3 | 1242 × 2688 |
| iPad 13" Display | 516 × 688 | 4 | 2064 × 2752 |

Capture with Ctrl+Shift+P → "Capture screenshot" (exports at full physical resolution). The iPhone 6.5" slot covers all large iPhones. For iPad, use 2064×2752 **or** 2048×2732 (512 × 683 @ DPR 4) — never a mix.

## 4. App Privacy declarations

For Supabase email/password auth with profile and activity tables:

| Data type | Collected | Linked to identity | Used for tracking |
|---|---|---|---|
| Name | Yes | Yes | No |
| Email Address | Yes | Yes | No |
| User ID | Yes | Yes | No |
| Other Usage Data (in-app activity) | Yes | Yes | No |

> Answered by reading the actual `services/` and database schema — not from memory.

## 5. TestFlight setup

- Created an Internal Testing group under TestFlight
- Added the two testers by Apple ID email
- Assigned the "Ready to Test" build via the Builds tab
- Internal testers receive no email invite — the app appears directly in TestFlight once the build is assigned

## 6. Submission status

- Build-number conflict resolved: triggered a fresh `eas build` with `autoIncrement: true` in `eas.json` (Apple had burned the previous number on the failed upload)
- New build uploaded, all gating fields and App Privacy complete
- **"Add for Review" available → app submitted for review**
