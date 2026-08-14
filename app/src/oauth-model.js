import crypto from 'node:crypto'
import jwt from 'jsonwebtoken'

const accessTokens = new Map()
const allowedScopes = new Set([
  'inventory:read',
  'inventory:write',
])

function requireEnvironment(name) {
  const value = process.env[name]

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`)
  }

  return value
}

function tokenLifetime() {
  const lifetime = Number(process.env.TOKEN_TTL_SECONDS || 300)

  return Number.isFinite(lifetime) && lifetime > 0
    ? lifetime
    : 300
}

function safeEqual(actual, expected) {
  const actualBuffer = Buffer.from(String(actual || ''))
  const expectedBuffer = Buffer.from(String(expected || ''))

  if (actualBuffer.length !== expectedBuffer.length) {
    return false
  }

  return crypto.timingSafeEqual(actualBuffer, expectedBuffer)
}

function configuredClient() {
  return {
    id: requireEnvironment('CLIENT_ID'),
    grants: ['client_credentials'],
    accessTokenLifetime: tokenLifetime(),
    allowedScopes: [...allowedScopes],
  }
}

const oauthModel = {
  async getClient(clientId, clientSecret) {
    const client = configuredClient()
    const expectedSecret = requireEnvironment('CLIENT_SECRET')

    if (
      !safeEqual(clientId, client.id) ||
      !safeEqual(clientSecret, expectedSecret)
    ) {
      return false
    }

    return client
  },

  async getUserFromClient(client) {
    return {
      id: client.id,
      type: 'service-account',
    }
  },

  async validateScope(_user, client, requestedScopes) {
    const scopes = requestedScopes?.length
      ? requestedScopes
      : ['inventory:read']

    const permittedScopes = new Set(client.allowedScopes || [])

    return scopes.every((scope) => permittedScopes.has(scope))
      ? scopes
      : false
  },

  async generateAccessToken(client, user, scope) {
    return jwt.sign(
      {
        client_id: client.id,
        scope: scope || [],
        type: user.type,
      },
      requireEnvironment('JWT_SECRET'),
      {
        algorithm: 'HS256',
        audience: 'securestock-api',
        issuer: 'securestock-auth-server',
        subject: user.id,
        expiresIn: tokenLifetime(),
        jwtid: crypto.randomUUID(),
      },
    )
  },

  async saveToken(token, client, user) {
    const savedToken = {
      ...token,
      client: { id: client.id },
      user: {
        id: user.id,
        type: user.type,
      },
    }

    accessTokens.set(token.accessToken, savedToken)
    return savedToken
  },

  async getAccessToken(accessToken) {
    try {
      jwt.verify(
        accessToken,
        requireEnvironment('JWT_SECRET'),
        {
          algorithms: ['HS256'],
          audience: 'securestock-api',
          issuer: 'securestock-auth-server',
        },
      )
    } catch {
      return false
    }

    return accessTokens.get(accessToken) || false
  },

  async verifyScope(token, requiredScopes) {
    if (!Array.isArray(token.scope)) {
      return false
    }

    return requiredScopes.every((scope) =>
      token.scope.includes(scope),
    )
  },
}

export default oauthModel
