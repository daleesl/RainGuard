export function AdminMiniTable({ children, className = '' }) {
  return (
    <div className={['mini-table', className].filter(Boolean).join(' ')}>
      {children}
    </div>
  )
}

export function AdminMiniTableHeader({ columns }) {
  return (
    <div className="mini-table-header">
      {columns.map((column) => (
        <span key={column}>{column}</span>
      ))}
    </div>
  )
}

export function AdminMiniTableRow({ children }) {
  return <div className="mini-table-row">{children}</div>
}
