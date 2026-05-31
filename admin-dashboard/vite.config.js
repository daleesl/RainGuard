import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return undefined
          if (id.includes('firebase')) return 'firebase'
          if (id.includes('leaflet') || id.includes('react-leaflet')) {
            return 'map'
          }
          if (id.includes('lucide-react')) return 'icons'
          if (id.includes('react')) return 'react'
          return 'vendor'
        },
      },
    },
  },
  plugins: [react(), tailwindcss()],
})
