const toneClasses = {
  amber: 'min-w-[112px] bg-[#fff5dc] text-[#b26b00]',
  blue: 'bg-[#e7f4ff] text-[#1778d4]',
  green: 'bg-[#e7f8f3] text-[#28a985]',
  neutral: 'bg-[#eef6fb] text-[#667b8f]',
  red: 'bg-[#ffe9e9] text-[#e24d4d]',
}

export function FilterChipButton({
  children,
  className = '',
  disabled = false,
  isActive = false,
  onClick,
  tone = 'blue',
}) {
  const classes = [
    'inline-flex h-6 min-w-[72px] items-center justify-center rounded-full px-4',
    'text-[9px] font-extrabold uppercase tracking-[0.05em]',
    'border-0 transition duration-150 ease-out',
    'hover:shadow-[0_6px_16px_rgba(8,33,56,0.08)] focus-visible:outline-none',
    'active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50',
    isActive ? 'shadow-[inset_0_0_0_1px_currentColor] saturate-[1.08]' : '',
    toneClasses[tone] || toneClasses.blue,
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <button
      className={classes}
      data-active={isActive ? 'true' : 'false'}
      disabled={disabled}
      onClick={onClick}
      type="button"
    >
      {children}
    </button>
  )
}
