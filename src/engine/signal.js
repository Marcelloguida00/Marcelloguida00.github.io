import gsap from 'gsap'
import { prefersReducedMotion } from './env'

/** One driver: scroll progress + idle breath → --signal on <html> */
export function createSignalDriver() {
  const root = document.documentElement
  let base = 0
  let breath = 0
  let breathTween = null

  const apply = () => {
    const value = Math.min(1, Math.max(0, base + breath))
    root.style.setProperty('--signal', value.toFixed(4))
  }

  const setProgress = (progress) => {
    // Ease into signal so early page stays hush, work section sings
    base = Math.pow(Math.min(1, Math.max(0, progress)), 0.85)
    apply()
  }

  if (!prefersReducedMotion()) {
    breathTween = gsap.to(
      { v: 0 },
      {
        v: 0.035,
        duration: 3.2,
        ease: 'sine.inOut',
        yoyo: true,
        repeat: -1,
        onUpdate() {
          breath = this.targets()[0].v
          apply()
        },
      }
    )
  }

  apply()

  return {
    setProgress,
    destroy() {
      breathTween?.kill()
      root.style.setProperty('--signal', '0')
    },
  }
}
