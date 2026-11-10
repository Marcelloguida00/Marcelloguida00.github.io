export const ease = {
  out: 'expo.out',
  soft: 'power3.out',
  inOut: 'expo.inOut',
}

export function prefersReducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

export function canHover() {
  return window.matchMedia('(hover: hover) and (pointer: fine)').matches
}
