import { useEffect, useState } from "react";
import { useParams, Link } from "react-router-dom";
import {
  Descriptions,
  Tag,
  Table,
  Button,
  Modal,
  Form,
  InputNumber,
  Select,
  DatePicker,
  Input,
  Typography,
  Space,
  Skeleton,
  message,
} from "antd";
import dayjs from "dayjs";
import { fetchEmployee, addSalaryRecord, updateEmployee } from "../api/employees";
import useReferenceData from "../context/useReferenceData";
import { formatMoney, formatUsd } from "../utils/format";

const { Title } = Typography;

const STATUS_COLORS = { active: "green", terminated: "default" };

export default function EmployeeDetailPage() {
  const { id } = useParams();
  const { departments, statuses, currencies, country_currencies } = useReferenceData();

  const [employee, setEmployee] = useState(null);
  const [raiseModalOpen, setRaiseModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [raiseForm] = Form.useForm();
  const [editForm] = Form.useForm();

  const load = () => fetchEmployee(id).then(setEmployee);

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  if (!employee) {
    return <Skeleton active />;
  }

  const currentCurrency = employee.current_salary?.currency ?? country_currencies[employee.country];

  const handleAddRaise = async () => {
    const values = await raiseForm.validateFields();
    try {
      const updated = await addSalaryRecord(employee.id, {
        salary_record: {
          amount: values.amount,
          currency: values.currency,
          effective_date: values.effective_date.format("YYYY-MM-DD"),
          reason: values.reason,
        },
      });
      setEmployee(updated);
      setRaiseModalOpen(false);
      raiseForm.resetFields();
      message.success("Salary record added");
    } catch (error) {
      const errors = error?.response?.data?.errors ?? ["Something went wrong"];
      message.error(errors.join(", "));
    }
  };

  const handleEdit = async () => {
    const values = await editForm.validateFields();
    try {
      const updated = await updateEmployee(employee.id, { employee: values });
      setEmployee(updated);
      setEditModalOpen(false);
      message.success("Employee updated");
    } catch (error) {
      const errors = error?.response?.data?.errors ?? ["Something went wrong"];
      message.error(errors.join(", "));
    }
  };

  const salaryColumns = [
    { title: "Effective Date", dataIndex: "effective_date" },
    {
      title: "Amount",
      dataIndex: "amount",
      render: (amount, record) => (
        <span className="tabular-nums">{formatMoney(amount, record.currency)}</span>
      ),
    },
    {
      title: "USD Equivalent",
      dataIndex: "amount_usd",
      render: (value) => <span className="tabular-nums">{formatUsd(value)}</span>,
    },
    { title: "Reason", dataIndex: "reason" },
  ];

  return (
    <div>
      <Space style={{ width: "100%", justifyContent: "space-between", marginBottom: 16 }}>
        <Title level={3} style={{ margin: 0 }}>
          {employee.full_name}
        </Title>
        <Space>
          <Button
            onClick={() => {
              editForm.setFieldsValue({
                first_name: employee.first_name,
                last_name: employee.last_name,
                email: employee.email,
                department: employee.department,
                job_title: employee.job_title,
                status: employee.status,
              });
              setEditModalOpen(true);
            }}
          >
            Edit Details
          </Button>
          <Button type="primary" onClick={() => setRaiseModalOpen(true)}>
            Record Salary Change
          </Button>
        </Space>
      </Space>

      <Descriptions bordered column={2} size="small" style={{ marginBottom: 24 }}>
        <Descriptions.Item label="Employee #">{employee.employee_number}</Descriptions.Item>
        <Descriptions.Item label="Status">
          <Tag color={STATUS_COLORS[employee.status]}>{employee.status}</Tag>
        </Descriptions.Item>
        <Descriptions.Item label="Email">{employee.email}</Descriptions.Item>
        <Descriptions.Item label="Hire Date">{employee.hire_date}</Descriptions.Item>
        <Descriptions.Item label="Country">{employee.country}</Descriptions.Item>
        <Descriptions.Item label="Department">{employee.department}</Descriptions.Item>
        <Descriptions.Item label="Job Title">{employee.job_title}</Descriptions.Item>
        <Descriptions.Item label="Current Salary">
          {employee.current_salary
            ? `${formatMoney(employee.current_salary.amount, employee.current_salary.currency)} (${formatUsd(
                employee.current_salary.amount_usd
              )})`
            : "—"}
        </Descriptions.Item>
      </Descriptions>

      <Title level={4}>Salary History</Title>
      <Table
        rowKey="id"
        columns={salaryColumns}
        dataSource={employee.salary_history}
        pagination={false}
      />

      <Modal
        title="Record a Salary Change"
        open={raiseModalOpen}
        onOk={handleAddRaise}
        onCancel={() => setRaiseModalOpen(false)}
        okText="Save"
      >
        <Form form={raiseForm} layout="vertical" initialValues={{ currency: currentCurrency }}>
          <Form.Item name="amount" label="Amount" rules={[{ required: true }]}>
            <InputNumber style={{ width: "100%" }} min={0.01} step={1000} />
          </Form.Item>
          <Form.Item name="currency" label="Currency" rules={[{ required: true }]}>
            <Select options={currencies.map((c) => ({ value: c, label: c }))} />
          </Form.Item>
          <Form.Item
            name="effective_date"
            label="Effective Date"
            rules={[{ required: true }]}
            initialValue={dayjs()}
          >
            <DatePicker style={{ width: "100%" }} />
          </Form.Item>
          <Form.Item name="reason" label="Reason">
            <Input placeholder="e.g. Annual raise, Promotion" />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Edit Employee Details"
        open={editModalOpen}
        onOk={handleEdit}
        onCancel={() => setEditModalOpen(false)}
        okText="Save"
      >
        <Form form={editForm} layout="vertical">
          <Form.Item name="first_name" label="First Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="last_name" label="Last Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: "email" }]}>
            <Input />
          </Form.Item>
          <Form.Item name="department" label="Department" rules={[{ required: true }]}>
            <Select options={departments.map((d) => ({ value: d, label: d }))} />
          </Form.Item>
          <Form.Item name="job_title" label="Job Title" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="status" label="Status" rules={[{ required: true }]}>
            <Select options={statuses.map((s) => ({ value: s, label: s }))} />
          </Form.Item>
        </Form>
      </Modal>

      <div style={{ marginTop: 16 }}>
        <Link to="/">← Back to employees</Link>
      </div>
    </div>
  );
}
