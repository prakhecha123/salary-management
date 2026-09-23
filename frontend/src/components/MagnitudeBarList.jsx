// A minimal single-hue horizontal bar list for comparing one magnitude
// across categories (e.g. total payroll by country). Deliberately not a
// full charting library: one hue means length alone carries the
// comparison, which is all this view needs.
export default function MagnitudeBarList({ rows, labelKey, valueKey, formatValue }) {
  const maxValue = Math.max(...rows.map((row) => row[valueKey]), 1);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {rows.map((row) => (
        <div key={row[labelKey]} style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 140, fontSize: 13, color: "#52514e", flexShrink: 0 }}>
            {row[labelKey]}
          </div>
          <div style={{ flex: 1, background: "#f0efec", borderRadius: 4, height: 20, position: "relative" }}>
            <div
              data-testid="magnitude-bar"
              style={{
                width: `${(row[valueKey] / maxValue) * 100}%`,
                background: "#2a78d6",
                height: "100%",
                borderRadius: 4,
              }}
            />
          </div>
          <div className="tabular-nums" style={{ width: 110, textAlign: "right", fontSize: 13, color: "#0b0b0b" }}>
            {formatValue(row[valueKey])}
          </div>
        </div>
      ))}
    </div>
  );
}
