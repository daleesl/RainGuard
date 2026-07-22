const ACTION_TONE_CLASSES = {
  danger:
    'bg-[#fee2e2] text-[#dc2626] hover:bg-[#fecaca] focus-visible:bg-[#fecaca]',
  ghost:
    'border border-[#cbd5e1] bg-white text-[#475569] hover:border-[#64748b] hover:text-[#334155] focus-visible:border-[#64748b] focus-visible:text-[#334155]',
  primary:
    'bg-[#dbeafe] text-[#2563eb] hover:bg-[#bfdbfe] focus-visible:bg-[#bfdbfe]',
  resolve:
    'bg-[#dbeafe] text-[#2563eb] hover:bg-[#bfdbfe] focus-visible:bg-[#bfdbfe]',
  verify:
    'bg-[#dcfce7] text-[#16a34a] hover:bg-[#bbf7d0] focus-visible:bg-[#bbf7d0]',
}

/**
 * @typedef {'danger' | 'ghost' | 'primary' | 'resolve' | 'verify'} AdminActionTone
 *
 * @typedef {Object} AdminActionButtonProps
 * @property {import('react').ReactNode} children
 * @property {string} [className]
 * @property {boolean} [disabled]
 * @property {import('lucide-react').LucideIcon} [icon]
 * @property {() => void} [onClick]
 * @property {string} [title]
 * @property {AdminActionTone} [tone]
 */

/** @param {AdminActionButtonProps} props */
export function AdminActionButton({
  children,
  className = '',
  disabled = false,
  icon: Icon,
  onClick,
  title,
  tone = 'primary',
}) {
  const toneClass = ACTION_TONE_CLASSES[tone] || ACTION_TONE_CLASSES.primary

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

/**
 * @param {{
 *   children: import('react').ReactNode,
 *   className?: string,
 * }} props
 */
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
