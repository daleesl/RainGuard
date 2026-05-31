export function StatusChip({
  children,
  className = '',
  size = 'default',
  tone = 'blue',
}) {
  const normalizedTone = tone.startsWith('chip-') ? tone.replace('chip-', '') : tone
  const toneClass = {
    amber: 'bg-[#fff5dc] text-[#b26b00]',
    blue: 'bg-[#e7f4ff] text-[#1778d4]',
    green: 'bg-[#e7f8f3] text-[#28a985]',
    neutral: 'bg-[#eef6fb] text-[#667b8f]',
    red: 'bg-[#ffe9e9] text-[#e24d4d]',
  }[normalizedTone] || 'bg-[#e7f4ff] text-[#1778d4]'
  const sizeClass =
    size === 'mini'
      ? 'h-6 min-w-[74px] px-2.5 text-[8px]'
      : 'h-6 min-w-[72px] px-4 text-[9px] tracking-[0.05em]'

  return (
    <span
      className={[
        'inline-flex w-fit items-center justify-center rounded-full font-black uppercase',
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
