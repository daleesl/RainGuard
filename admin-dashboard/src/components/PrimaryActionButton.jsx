export function PrimaryActionButton({
  children,
  className = '',
  disabled = false,
  onClick,
  type = 'button',
}) {
  const classes = [
    'h-[38px] w-[174px] shrink-0 rounded-full border-0 bg-[#1778d4]',
    'text-[10px] font-extrabold text-white transition',
    'duration-150 ease-out hover:bg-[#0f6cc4] hover:shadow-[0_8px_18px_rgba(23,120,212,0.16)]',
    'active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60',
    'max-[1360px]:w-[150px] max-[760px]:w-full',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <button
      className={classes}
      disabled={disabled}
      onClick={onClick}
      type={type}
    >
      {children}
    </button>
  )
}
