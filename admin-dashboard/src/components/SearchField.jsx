import { Search } from 'lucide-react'

export function SearchField({
  ariaLabel = 'Search admin records',
  onChange,
  placeholder = 'Search admin records',
  value,
}) {
  return (
    <label className="flex h-9 w-[min(300px,28vw)] min-w-[220px] items-center gap-[9px] rounded-full border border-[#d9e7ef] bg-[#f4fafd] px-[18px] text-[#667b8f] max-[1360px]:w-[250px] max-[1360px]:min-w-[210px] max-[760px]:w-full max-[760px]:min-w-0">
      <Search aria-hidden="true" className="shrink-0" size={14} />
      <input
        aria-label={ariaLabel}
        className="w-full border-0 bg-transparent text-[10px] text-[#102033] outline-none placeholder:text-[#667b8f]"
        onChange={(event) => onChange(event.target.value)}
        placeholder={placeholder}
        type="search"
        value={value}
      />
    </label>
  )
}
