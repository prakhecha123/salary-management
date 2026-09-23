import { describe, it, expect } from "vitest";
import { formatMoney, formatUsd } from "./format";

describe("formatMoney", () => {
  it("formats a whole-dollar amount with the currency symbol", () => {
    expect(formatMoney(100000, "USD")).toBe("$100,000");
  });

  it("formats a non-USD currency with its own symbol", () => {
    expect(formatMoney(83000, "INR")).toBe("₹83,000");
  });

  it("rounds to whole units", () => {
    expect(formatMoney(1234.56, "USD")).toBe("$1,235");
  });

  it("returns an em dash placeholder for a missing amount", () => {
    expect(formatMoney(null, "USD")).toBe("—");
    expect(formatMoney(undefined, "USD")).toBe("—");
  });
});

describe("formatUsd", () => {
  it("formats in USD", () => {
    expect(formatUsd(50000)).toBe("$50,000");
  });
});
