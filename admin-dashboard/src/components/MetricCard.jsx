export function MetricCard({ accent, className = '', helper, icon: Icon, label, value }) {
  return (
    <article
      className={[
        'relative min-h-[86px] overflow-hidden rounded-2xl border border-[#d9e7ef]',
        'bg-white py-[13px] pr-[18px] pb-3 pl-[18px]',
        'shadow-[0_8px_18px_rgba(8,33,56,0.05)]',
        'before:absolute before:inset-y-0 before:left-0 before:w-[5px]',
        'before:rounded-2xl before:bg-[var(--metric-accent)]',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      style={{ '--metric-accent': accent }}
    >
      {Icon ? (
        <span className="dashboard-metric-icon">
          <Icon aria-hidden="true" size={16} />
        </span>
      ) : null}
      <p className="m-0 text-[8px] font-extrabold uppercase leading-snug tracking-[0.08em] text-[#667b8f]">
        {label}
      </p>
      <strong className="mt-1.5 block text-[22px] font-extrabold leading-tight text-[#102033]">
        {value}
      </strong>
      <span className="mt-0.5 block text-[9px] text-[#697b8c]">{helper}</span>
    </article>
  )
}
