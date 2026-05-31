export function AdminActionButton({
  children,
  className = '',
  disabled = false,
  icon: Icon,
  onClick,
  title,
  tone = 'primary',
}) {
  const toneClass = {
    danger:
      'bg-[#ffe4e4] text-[#e24d4d] hover:bg-[#ffd8d8] focus-visible:bg-[#ffd8d8]',
    ghost:
      'border border-[#d9e7ef] bg-white text-[#102033] hover:border-[#1778d4] hover:text-[#1778d4] focus-visible:border-[#1778d4] focus-visible:text-[#1778d4]',
    primary:
      'bg-[#e7f4ff] text-[#1778d4] hover:bg-[#d9ecff] focus-visible:bg-[#d9ecff]',
    resolve:
      'bg-[#e7f4ff] text-[#1778d4] hover:bg-[#d9ecff] focus-visible:bg-[#d9ecff]',
    verify:
      'bg-[#e7f4ff] text-[#1778d4] hover:bg-[#d9ecff] focus-visible:bg-[#d9ecff]',
  }[tone]

  return (
    <button
      className={[
        'inline-flex h-[30px] min-w-[72px] items-center justify-center gap-[6px]',
        'rounded-full px-[9px] text-[9px] font-black leading-none',
        'transition duration-150 ease-out hover:shadow-[0_6px_14px_rgba(23,120,212,0.08)]',
        'focus-visible:outline-none active:scale-[0.98]',
        'disabled:cursor-not-allowed disabled:opacity-50',
        'max-[1440px]:min-w-[68px] max-[1440px]:px-[7px]',
        toneClass,
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      disabled={disabled}
      onClick={onClick}
      title={title}
      type="button"
    >
      {Icon ? <Icon aria-hidden="true" className="shrink-0" size={13} /> : null}
      <span className="min-w-0 whitespace-nowrap">{children}</span>
    </button>
  )
}

export function AdminActionGroup({ children, className = '' }) {
  return (
    <div
      className={[
        'flex min-w-[188px] flex-wrap items-center justify-end gap-2',
        'max-[1440px]:min-w-[170px]',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
    >
      {children}
    </div>
  )
}
