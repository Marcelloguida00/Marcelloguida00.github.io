import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

/** Prefer public/ directory indexes over SPA fallback (SEO landing pages). */
function staticDirIndex() {
  const map = {
    '/servizi': '/servizi/index.html',
    '/servizi/': '/servizi/index.html',
    '/services': '/services/index.html',
    '/services/': '/services/index.html',
  }
  return {
    name: 'static-dir-index',
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        const path = req.url?.split('?')[0]
        if (path && map[path]) req.url = map[path] + (req.url.includes('?') ? `?${req.url.split('?')[1]}` : '')
        next()
      })
    },
    configurePreviewServer(server) {
      server.middlewares.use((req, _res, next) => {
        const path = req.url?.split('?')[0]
        if (path && map[path]) req.url = map[path] + (req.url.includes('?') ? `?${req.url.split('?')[1]}` : '')
        next()
      })
    },
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), staticDirIndex()],
  build: {
    outDir: 'docs',
  },
})
