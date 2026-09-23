import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import MagnitudeBarList from "./MagnitudeBarList";

describe("MagnitudeBarList", () => {
  const rows = [
    { name: "United States", total: 300 },
    { name: "India", total: 100 },
    { name: "Germany", total: 150 },
  ];

  it("renders a label and formatted value for each row", () => {
    render(
      <MagnitudeBarList
        rows={rows}
        labelKey="name"
        valueKey="total"
        formatValue={(value) => `$${value}`}
      />
    );

    expect(screen.getByText("United States")).toBeInTheDocument();
    expect(screen.getByText("$300")).toBeInTheDocument();
    expect(screen.getByText("India")).toBeInTheDocument();
    expect(screen.getByText("$100")).toBeInTheDocument();
  });

  it("sizes each bar proportionally to the largest value in the list", () => {
    render(
      <MagnitudeBarList rows={rows} labelKey="name" valueKey="total" formatValue={String} />
    );

    const widths = screen.getAllByTestId("magnitude-bar").map((bar) => bar.style.width);

    expect(widths).toEqual(["100%", "33.33333333333333%", "50%"]);
  });

  it("treats an empty row list as a max of 1 rather than dividing by zero", () => {
    render(<MagnitudeBarList rows={[]} labelKey="name" valueKey="total" formatValue={String} />);

    expect(screen.queryAllByTestId("magnitude-bar")).toHaveLength(0);
  });
});
