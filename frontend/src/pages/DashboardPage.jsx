import { useEffect, useState } from "react";
import { Typography, Row, Col, Card, Skeleton, Table } from "antd";
import { fetchAnalyticsOverview } from "../api/analytics";
import { formatUsd } from "../utils/format";
import StatTile from "../components/StatTile";
import MagnitudeBarList from "../components/MagnitudeBarList";

const { Title } = Typography;

const breakdownColumns = (labelTitle, labelKey) => [
  { title: labelTitle, dataIndex: labelKey },
  { title: "Headcount", dataIndex: "headcount", align: "right" },
  {
    title: "Total Payroll (USD)",
    dataIndex: "total_payroll_usd",
    align: "right",
    render: formatUsd,
  },
  {
    title: "Average Salary (USD)",
    dataIndex: "average_salary_usd",
    align: "right",
    render: formatUsd,
  },
  { title: "Min (USD)", dataIndex: "min_salary_usd", align: "right", render: formatUsd },
  { title: "Max (USD)", dataIndex: "max_salary_usd", align: "right", render: formatUsd },
];

export default function DashboardPage() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetchAnalyticsOverview().then(setData);
  }, []);

  if (!data) {
    return <Skeleton active />;
  }

  const { overall, by_country: byCountry, by_department: byDepartment } = data;

  return (
    <div>
      <Title level={3}>Payroll Dashboard</Title>
      <p style={{ color: "#52514e", marginTop: -8, marginBottom: 24 }}>
        Active employees only, converted to USD using the exchange rates in{" "}
        <code>reference_data</code>. See <code>docs/trade-offs.md</code> for why this is a
        static table rather than a live rate.
      </p>

      <Row gutter={16} style={{ marginBottom: 32 }}>
        <Col flex="1">
          <StatTile label="Active Headcount" value={overall.headcount.toLocaleString()} />
        </Col>
        <Col flex="1">
          <StatTile label="Total Payroll" value={formatUsd(overall.total_payroll_usd)} />
        </Col>
        <Col flex="1">
          <StatTile label="Average Salary" value={formatUsd(overall.average_salary_usd)} />
        </Col>
      </Row>

      <Row gutter={32} style={{ marginBottom: 32 }}>
        <Col span={12}>
          <Title level={5}>Total Payroll by Country</Title>
          <MagnitudeBarList
            rows={byCountry}
            labelKey="country"
            valueKey="total_payroll_usd"
            formatValue={formatUsd}
          />
        </Col>
        <Col span={12}>
          <Title level={5}>Total Payroll by Department</Title>
          <MagnitudeBarList
            rows={byDepartment}
            labelKey="department"
            valueKey="total_payroll_usd"
            formatValue={formatUsd}
          />
        </Col>
      </Row>

      <Card title="By Country" style={{ marginBottom: 24 }}>
        <Table
          rowKey="country"
          columns={breakdownColumns("Country", "country")}
          dataSource={byCountry}
          pagination={false}
        />
      </Card>

      <Card title="By Department">
        <Table
          rowKey="department"
          columns={breakdownColumns("Department", "department")}
          dataSource={byDepartment}
          pagination={false}
        />
      </Card>
    </div>
  );
}
