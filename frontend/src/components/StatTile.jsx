export default function StatTile({ label, value }) {
  return (
    <div
      style={{
        background: "#fcfcfb",
        border: "1px solid #e1e0d9",
        borderRadius: 8,
        padding: "16px 20px",
        minWidth: 200,
        flex: 1,
      }}
    >
      <div style={{ color: "#898781", fontSize: 13, marginBottom: 6 }}>{label}</div>
      <div className="tabular-nums" style={{ fontSize: 28, fontWeight: 600, color: "#0b0b0b" }}>
        {value}
      </div>
    </div>
  );
}
