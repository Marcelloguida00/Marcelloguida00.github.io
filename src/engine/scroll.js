import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import Lenis from 'lenis'
import { prefersReducedMotion } from './env'

gsap.registerPlugin(ScrollTrigger)

let lenis = null
let tickerFn = null

export function initScroll(onScroll) {
  if (prefersReducedMotion()) {
    ScrollTrigger.normalizeScroll(false)
    const onNative = () => {
      const y = window.scrollY
      const max = document.documentElement.scrollHeight - window.innerHeight
      onScroll?.({ y, velocity: 0, progress: max > 0 ? y / max : 0 })
    }
    window.addEventListener('scroll', onNative, { passive: true })
    onNative()
    return () => window.removeEventListener('scroll', onNative)
  }

  lenis = new Lenis({
    duration: 1.1,
    smoothWheel: true,
    touchMultiplier: 1.4,
  })

  lenis.on('scroll', (e) => {
    ScrollTrigger.update()
    const max = e.limit || 1
    onScroll?.({
      y: e.scroll,
      velocity: e.velocity,
      progress: max > 0 ? e.scroll / max : 0,
    })
  })

  tickerFn = (time) => {
    lenis?.raf(time * 1000)
  }
  gsap.ticker.add(tickerFn)
  gsap.ticker.lagSmoothing(0)

  return () => {
    if (tickerFn) gsap.ticker.remove(tickerFn)
    lenis?.destroy()
    lenis = null
  }
}

export function getLenis() {
  return lenis
}
