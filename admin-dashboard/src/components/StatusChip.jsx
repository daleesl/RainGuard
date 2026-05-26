export function StatusChip({
  children,
  className = '',
  size = 'default',
  tone = 'blue',
}) {
  const baseClass = size === 'mini' ? 'mini-chip' : 'chip'
  const toneClass = tone.startsWith('chip-') ? tone : `chip-${tone}`

  return (
    <span className={[baseClass, toneClass, className].filter(Boolean).join(' ')}>
      {children}
    </span>
  )
}
