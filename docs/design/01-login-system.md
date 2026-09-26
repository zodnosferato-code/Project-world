# Design: Login System (Quarkus)

## Goal

HTTP-based registration and login for the MMO backend. The Quarkus app handles auth; the Netty game server handles gameplay. Both share the same PostgreSQL database.

## Architecture

```
Client (game client)
   |
   |  POST /auth/register, POST /auth/login
   v
Quarkus HTTP server (RESTEasy Reactive)
   |
   |  BCrypt hash / verify
   |  JWT sign (smallrye-jwt-build)
   v
PostgreSQL (Dev Services in dev mode)
   |
   |  shared DB
   v
Netty game server (reads user/character data, no auth logic)
```

## Endpoints

### POST /auth/register

Request:
```json
{ "username": "alice", "password": "secret123", "characterName": "Alice" }
```

Behavior:
- Validate input (username 3-20 chars, password min 8 chars, character name unique)
- Check username is not already taken -> 409 Conflict if taken
- Hash password with BCrypt (cost 10, via `io.quarkus.elytron.security.common.BcryptUtil`)
- Insert user row + character row in one transaction
- Return 201 Created with the new user id

### POST /auth/login

Request:
```json
{ "username": "alice", "password": "secret123" }
```

Behavior:
- Look up user by username -> 401 if not found
- Verify password with `BcryptUtil.matches(plain, hash)` -> 401 if mismatch
- Sign a JWT with `smallrye-jwt-build`:
  - subject: user id
  - claim `username`
  - claim `groups`: ["user"] (roles for @RolesAllowed)
  - expiry: 24 hours (configurable)
  - signed with RSA private key (PEM)
- Return 200 with the token

Response:
```json
{ "token": "eyJhbGciOiJSUzI1NiIs...", "expiresIn": 86400 }
```

## Security model

- Passwords: BCrypt only, never stored in plain text. Salt is generated per password.
- Tokens: JWT Bearer. Clients send `Authorization: Bearer <token>` on protected endpoints.
- Verification: `quarkus-smallrye-jwt` validates signature + expiry against the public key.
- Roles: `@RolesAllowed("user")` on protected resources; admin role reserved for later.
- Rate limiting: not in v1; add later if needed.

## Data model

### users
| column | type | notes |
|---|---|---|
| id | BIGSERIAL PK | |
| username | VARCHAR(20) UNIQUE NOT NULL | |
| password_hash | VARCHAR(60) NOT NULL | BCrypt modular crypt format |
| role | VARCHAR(20) NOT NULL DEFAULT 'user' | |
| created_at | TIMESTAMPTZ NOT NULL DEFAULT now() | |

### characters
| column | type | notes |
|---|---|---|
| id | BIGSERIAL PK | |
| user_id | BIGINT FK -> users(id) UNIQUE | one character per user in v1 |
| name | VARCHAR(20) UNIQUE NOT NULL | |
| level | INT NOT NULL DEFAULT 1 | |
| gold | INT NOT NULL DEFAULT 0 | |
| pos_x, pos_y | FLOAT NOT NULL DEFAULT 0 | last known position |
| updated_at | TIMESTAMPTZ | |

## Quarkus setup

Extensions:
- `quarkus-resteasy-reactive` (REST)
- `quarkus-hibernate-orm-panache` (entities + repositories)
- `quarkus-jdbc-postgresql` (Dev Services auto-starts Postgres)
- `quarkus-elytron-security-common` (BcryptUtil)
- `quarkus-smallrye-jwt` + `quarkus-smallrye-jwt-build` (verify + sign)

Config (`application.properties`):
```properties
quarkus.datasource.db-kind=postgresql
quarkus.hibernate-orm.database.generation=drop-and-create

mp.jwt.verify.issuer=https://project-world.local
mp.jwt.verify.publickey.location=publicKey.pem
smallrye.jwt.sign.key.location=privateKey.pem
```

Dev Services starts a Postgres container automatically when running `quarkus dev` (no manual DB setup). Default credentials: quarkus/quarkus.

## Error responses

| case | status |
|---|---|
| validation error | 400 |
| username taken | 409 |
| bad credentials | 401 |
| missing/invalid token on protected route | 401 |

## Open questions

- Refresh tokens vs. longer-lived access tokens?
- Email verification later?
- Should the Netty server also accept JWTs for in-game actions, or only the Quarkus HTTP layer?

## Next steps

1. Scaffold the Quarkus project with the extensions above.
2. Implement User + Character entities (Panache).
3. Implement AuthResource (register + login).
4. Generate RSA key pair for signing.
5. Write RestAssured tests for both endpoints.
6. Commit and push to this repo.
