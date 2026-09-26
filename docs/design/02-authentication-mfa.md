# Design: Authentication & MFA (Quarkus)

## Goal

Extend the login system with multi-factor authentication and account recovery, without introducing Keycloak. The Quarkus app remains the sole identity provider; the Netty game server stays auth-agnostic and only reads user/character data from the shared PostgreSQL database.

## Decisions

- **No Keycloak.** Identity stays in-app: BCrypt passwords, smallrye-jwt, and the quarkus-security-webauthn extension.
- **MFA = password + WebAuthn (passkey).** WebAuthn over TOTP: the private key never leaves the device, it is phishing-resistant, and codes cannot be forwarded. TOTP was considered and rejected for these reasons.
- **Email-based recovery** for lost devices / lost passkeys. One-time reset links sent via the quarkus-mailer extension.
- **Dev testing:** quarkus-mailpit Dev Service auto-starts Mailpit (SMTP sink + web UI + REST API) in dev mode — zero-config email testing, no real SMTP server needed.

## Architecture

```
Client (game client / browser)
   |
   |  1. POST /auth/login (password) -> JWT
   |  2. GET  /q/webauthn/login-options-challenge -> WebAuthn assertion
   v
Quarkus HTTP server (RESTEasy Reactive)
   |
   |  BCrypt verify / WebAuthn verify / JWT sign
   |  Mailer (SMTP) for recovery links
   v
PostgreSQL (Dev Services in dev mode)
   |
   |  shared DB
   v
Netty game server (reads user/character data, no auth logic)
```

## Flow 1: Registration

1. User registers with username + password (existing `POST /auth/register`).
2. Email verification: send a one-time link (see Flow 4 token mechanics). Account is usable after verification.
3. Passkey enrollment (optional but encouraged): client calls `GET /q/webauthn/register-options-challenge`, the authenticator generates a key pair, the public key is stored server-side.

## Flow 2: Login (MFA)

1. `POST /auth/login` with username + password -> short-lived JWT (or a pre-auth token).
2. If the user has registered WebAuthn credentials, the client calls `GET /q/webauthn/login-options-challenge`.
3. The authenticator prompts for biometric / PIN / security key; the signed assertion goes to the verify endpoint.
4. On success the client receives the full session JWT.
5. Password-only login remains as a fallback when the user has no passkey — but recovery codes (see below) should be added later so a lost device does not mean a lost account.

## Flow 3: Email recovery (password reset)

1. `POST /auth/password-reset/request` with `{ "email": "..." }`.
2. Server generates a cryptographically secure token (`SecureRandom`, >= 32 bytes), emails a one-time link, and stores **only the SHA-256 hash** of the raw token in `auth_tokens`.
3. Link expires in 15–20 minutes, is single-use, and is consumed immediately on success.
4. `POST /auth/password-reset/confirm` with `{ "token": "...", "newPassword": "..." }` verifies the hash, updates the BCrypt password, and invalidates the token.
5. **Anti-enumeration:** the HTTP response is identical whether or not the email exists (always 204). This prevents account discovery.
6. **Rate limit:** max 3 reset requests per email per hour to prevent inbox flooding.

## Token mechanics (shared by email verification + password reset)

- Purpose enum: `EMAIL_VERIFY`, `PASSWORD_RESET` (extendable with `MAGIC_LOGIN` later).
- Raw token exists only long enough to be emailed; the DB holds the hash.
- Short lifetime, single-use, immediate invalidation after use — even on failed attempts.
- Token leakage via logs/query params is mitigated by the short TTL and one-time consumption.

## Data model additions

### users (extended)

| column | type | notes |
|---|---|---|
| email | VARCHAR(255) UNIQUE | required for recovery + verification |
| email_verified | BOOLEAN NOT NULL DEFAULT false | |

### webauthn_credentials

| column | type | notes |
|---|---|---|
| id | BIGSERIAL PK | |
| user_id | BIGINT FK -> users(id) | |
| credential_id | bytea UNIQUE NOT NULL | WebAuthn credential ID |
| public_key_cose | bytea NOT NULL | COSE public key |
| signature_counter | BIGINT NOT NULL DEFAULT 0 | replay protection |
| created_at | TIMESTAMPTZ NOT NULL DEFAULT now() | |

### auth_tokens

| column | type | notes |
|---|---|---|
| id | BIGSERIAL PK | |
| user_id | BIGINT FK -> users(id) | |
| token_hash | VARCHAR(64) UNIQUE NOT NULL | SHA-256 of raw token |
| purpose | VARCHAR(20) NOT NULL | EMAIL_VERIFY / PASSWORD_RESET |
| expires_at | TIMESTAMPTZ NOT NULL | |
| used | BOOLEAN NOT NULL DEFAULT false | |
| used_at | TIMESTAMPTZ | |

## Quarkus setup

Extensions:
- `quarkus-security-webauthn` — REST endpoints for register/login challenges (form-based quarkus-mfa extension rejected: it does not fit the JWT API)
- `quarkus-mailer` — SMTP sending (imperative + reactive Mutiny API)
- `io.quarkiverse.mailpit:quarkus-mailpit` — Dev Service for Mailpit (dev/test only)
- Existing: `quarkus-elytron-security-common` (BcryptUtil), `quarkus-smallrye-jwt` + `quarkus-smallrye-jwt-build`

Config (`application.properties`):
```properties
quarkus.mailer.from=Project World <no-reply@project-world.local>
quarkus.mailer.host=localhost
quarkus.mailer.port=1025
quarkus.mailer.mock=false

# In dev mode the mailpit extension auto-wires SMTP; no manual config needed.
# Production: point at a real SMTP provider (Gmail app password, SES, etc.)
```

## Security notes

- WebAuthn private keys never leave the authenticator; server stores only public keys + counters.
- Password hashes: BCrypt, per-password salt (existing).
- Reset tokens: hashed at rest, short TTL, single-use.
- SMTP password in production should come from a secrets store (e.g. HashiCorp Vault via quarkus-vault), not plain config.
- Always return the same response for password-reset requests regardless of email existence.

## Open questions

- Recovery codes (offline backup) vs. email-only recovery?
- Should a successful password reset also revoke existing JWTs / WebAuthn sessions?
- WebAuthn on the Netty game server directly, or only through the Quarkus HTTP layer?

## Next steps

1. Add Flyway migrations: users (email columns), webauthn_credentials, auth_tokens.
2. Implement password login + registration endpoints with JWT (existing design, now with email verification).
3. Wire quarkus-security-webauthn: register + login challenge endpoints, credential persistence to webauthn_credentials.
4. Implement password-reset request/confirm endpoints with hashed one-time tokens + Mailer.
5. Add rate limiting on login and reset endpoints (quarkus-http / Redis-based).
6. Add refresh token rotation + logout endpoint.
7. Add SmallRye Health checks (DB + SMTP) for the deployment pipeline.
8. Integration tests via Mailpit's REST API (fetch sent emails, extract tokens, assert consumption).
9. Connect the game client / frontend to the new flows.
