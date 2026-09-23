import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Table, Select, Input, Tag, Typography, Space, Button } from "antd";
import { PlusOutlined } from "@ant-design/icons";
import { fetchEmployees } from "../api/employees";
import useReferenceData from "../context/useReferenceData";
import { formatMoney, formatUsd } from "../utils/format";

const { Title } = Typography;

const STATUS_COLORS = { active: "green", terminated: "default" };

export default function EmployeeListPage() {
  const { countries, departments, statuses } = useReferenceData();

  const [employees, setEmployees] = useState([]);
  const [meta, setMeta] = useState({ page: 1, per_page: 25, total_count: 0 });
  const [loading, setLoading] = useState(false);

  const [country, setCountry] = useState();
  const [department, setDepartment] = useState();
  const [status, setStatus] = useState();
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  useEffect(() => {
    const timeout = setTimeout(() => {
      setSearch(searchInput);
      setPage(1);
    }, 300);
    return () => clearTimeout(timeout);
  }, [searchInput]);

  useEffect(() => {
    setLoading(true);
    fetchEmployees({ country, department, status, q: search, page, per_page: meta.per_page })
      .then((data) => {
        setEmployees(data.employees);
        setMeta(data.meta);
      })
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [country, department, status, search, page]);

  const columns = [
    {
      title: "Employee",
      dataIndex: "full_name",
      render: (name, record) => (
        <Link to={`/employees/${record.id}`}>
          {name} <span style={{ color: "#898781" }}>({record.employee_number})</span>
        </Link>
      ),
    },
    { title: "Country", dataIndex: "country" },
    { title: "Department", dataIndex: "department" },
    { title: "Job Title", dataIndex: "job_title" },
    {
      title: "Status",
      dataIndex: "status",
      render: (value) => <Tag color={STATUS_COLORS[value]}>{value}</Tag>,
    },
    {
      title: "Current Salary",
      dataIndex: "current_salary",
      render: (salary) =>
        salary ? (
          <span className="tabular-nums">
            {formatMoney(salary.amount, salary.currency)}
            {salary.currency !== "USD" && (
              <span style={{ color: "#898781" }}> ({formatUsd(salary.amount_usd)})</span>
            )}
          </span>
        ) : (
          "—"
        ),
    },
  ];

  return (
    <div>
      <Space style={{ width: "100%", justifyContent: "space-between", marginBottom: 16 }}>
        <Title level={3} style={{ margin: 0 }}>
          Employees
        </Title>
        <Link to="/employees/new">
          <Button type="primary" icon={<PlusOutlined />}>
            Add Employee
          </Button>
        </Link>
      </Space>

      <Space style={{ marginBottom: 16 }} wrap>
        <Input.Search
          placeholder="Search name, email, or employee #"
          allowClear
          style={{ width: 280 }}
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
        />
        <Select
          placeholder="Country"
          allowClear
          style={{ width: 180 }}
          value={country}
          onChange={(value) => {
            setCountry(value);
            setPage(1);
          }}
          options={countries.map((c) => ({ value: c, label: c }))}
        />
        <Select
          placeholder="Department"
          allowClear
          style={{ width: 180 }}
          value={department}
          onChange={(value) => {
            setDepartment(value);
            setPage(1);
          }}
          options={departments.map((d) => ({ value: d, label: d }))}
        />
        <Select
          placeholder="Status"
          allowClear
          style={{ width: 140 }}
          value={status}
          onChange={(value) => {
            setStatus(value);
            setPage(1);
          }}
          options={statuses.map((s) => ({ value: s, label: s }))}
        />
      </Space>

      <Table
        rowKey="id"
        columns={columns}
        dataSource={employees}
        loading={loading}
        pagination={{
          current: meta.page,
          pageSize: meta.per_page,
          total: meta.total_count,
          showSizeChanger: false,
          showTotal: (total) => `${total.toLocaleString()} employees`,
          onChange: (nextPage) => setPage(nextPage),
        }}
      />
    </div>
  );
}
