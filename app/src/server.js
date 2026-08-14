import 'dotenv/config'
import express from 'express'
import rateLimit from 'express-rate-limit'
import helmet from 'helmet'
import OAuthServer from '@node-oauth/express-oauth-server'
import oauthModel from './oauth-model.js'

const app = express()
const port = Number(process.env.PORT || 4000)
const host = process.env.HOST || '127.0.0.1'

for (const variable of [
  'CLIENT_ID',
  'CLIENT_SECRET',
  'JWT_SECRET',
]) {
  if (!process.env[variable]) {
    throw new Error(
      `Missing required environment variable: ${variable}`,
    )
  }
}

app.disable('x-powered-by')
app.use(helmet())
app.use(express.json({ limit: '10kb' }))
app.use(
  express.urlencoded({
    extended: false,
    limit: '10kb',
  }),
)

app.use((request, response, next) => {
  const startedAt = Date.now()

  response.on('finish', () => {
    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        method: request.method,
        path: request.path,
        status: response.statusCode,
        duration_ms: Date.now() - startedAt,
      }),
    )
  })

  next()
})

const tokenLimiter = rateLimit({
  windowMs: 60_000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  message: {
    error: 'rate_limit_exceeded',
    error_description:
      'Too many failed token requests. Try again later.',
  },
})

const oauth = new OAuthServer({
  model: oauthModel,
  accessTokenLifetime: Number(
    process.env.TOKEN_TTL_SECONDS || 300,
  ),
  allowBearerTokensInQueryString: false,
})

const inventory = [
  {
    sku: 'MEDUSA-TSHIRT-BLK-M',
    name: 'Medusa T-Shirt',
    quantity: 24,
  },
  {
    sku: 'MEDUSA-HOODIE-WHT-L',
    name: 'Medusa Hoodie',
    quantity: 11,
  },
]

app.get('/health', (_request, response) => {
  response.json({
    status: 'ok',
    service: 'securestock-oauth-api',
  })
})

app.post(
  '/oauth/token',
  tokenLimiter,
  oauth.token(),
)

app.get(
  '/inventory',
  oauth.authenticate({
    scope: ['inventory:read'],
  }),
  (_request, response) => {
    response.json({ inventory })
  },
)

app.post(
  '/inventory/update',
  oauth.authenticate({
    scope: ['inventory:write'],
  }),
  (request, response) => {
    const { sku, quantity } = request.body
    const item = inventory.find(
      (entry) => entry.sku === sku,
    )

    if (
      !item ||
      !Number.isInteger(quantity) ||
      quantity < 0
    ) {
      return response.status(400).json({
        error: 'invalid_inventory_update',
      })
    }

    item.quantity = quantity

    return response.json({
      message: 'Inventory updated',
      item,
    })
  },
)

app.use((_request, response) => {
  response.status(404).json({
    error: 'route_not_found',
  })
})

app.listen(port, host, () => {
  console.log(
    `SecureStock API listening on http://${host}:${port}`,
  )
})
