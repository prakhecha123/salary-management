export function formatMoney(amount, currency) {
  if (amount == null) return "—";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatUsd(amount) {
  return formatMoney(amount, "USD");
}
