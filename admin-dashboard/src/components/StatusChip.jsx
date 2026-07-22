export function StatusChip({
  children,
  className = '',
  size = 'default',
  tone = 'blue',
}) {
  const normalizedTone = tone.startsWith('chip-') ? tone.replace('chip-', '') : tone
  const toneClass = {
    amber: 'bg-[#fff5dc] text-[#b26b00]',
    blue: 'bg-[#dbeafe] text-[#2563eb]',
    danger: 'bg-[#fee2e2] text-[#dc2626]',
    gray: 'bg-[#f1f5f9] text-[#475569]',
    green: 'bg-[#dcfce7] text-[#16a34a]',
    neutral: 'bg-[#f1f5f9] text-[#475569]',
    red: 'bg-[#fee2e2] text-[#dc2626]',
    slate: 'bg-[#f1f5f9] text-[#475569]',
    warning: 'bg-[#fef3c7] text-[#d97706]',
  }[normalizedTone] || 'bg-[#dbeafe] text-[#2563eb]'
  const sizeClass =
    size === 'mini'
      ? 'h-6 min-w-[74px] px-2.5 text-[9px]'
      : 'h-6 min-w-[72px] px-4 text-[10px]'

  return (
    <span
      className={[
        'inline-flex w-fit items-center justify-center rounded-full font-semibold',
        sizeClass,
        toneClass,
        className,
      ]
        .filter(Boolean)
        .join(' ')}
    >
      {children}
    </span>
  )
}
