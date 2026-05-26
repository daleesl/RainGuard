import { Search } from 'lucide-react'

export function SearchField({
  ariaLabel = 'Search admin records',
  onChange,
  placeholder = 'Search admin records',
  value,
}) {
  return (
    <label className="search-field">
      <Search aria-hidden="true" size={14} />
      <input
        aria-label={ariaLabel}
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        type="search"
        value={value}
      />
    </label>
  )
}
