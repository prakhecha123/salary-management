import { useNavigate } from "react-router-dom";
import { Form, Input, Select, DatePicker, InputNumber, Button, Typography, Card, App } from "antd";
import dayjs from "dayjs";
import { createEmployee } from "../api/employees";
import useReferenceData from "../context/useReferenceData";

const { Title } = Typography;

export default function NewEmployeePage() {
  const navigate = useNavigate();
  const { message } = App.useApp();
  const { countries, departments, statuses, currencies, country_currencies } = useReferenceData();
  const [form] = Form.useForm();

  const handleCountryChange = (country) => {
    form.setFieldValue(["initial_salary", "currency"], country_currencies[country]);
  };

  const handleSubmit = async (values) => {
    try {
      const employee = await createEmployee({
        employee: {
          first_name: values.first_name,
          last_name: values.last_name,
          email: values.email,
          country: values.country,
          department: values.department,
          job_title: values.job_title,
          status: values.status,
          hire_date: values.hire_date.format("YYYY-MM-DD"),
        },
        initial_salary: {
          amount: values.initial_salary.amount,
          currency: values.initial_salary.currency,
          effective_date: values.hire_date.format("YYYY-MM-DD"),
          reason: "Initial offer",
        },
      });
      message.success("Employee created");
      navigate(`/employees/${employee.id}`);
    } catch (error) {
      const errors = error?.response?.data?.errors ?? ["Something went wrong"];
      message.error(errors.join(", "));
    }
  };

  return (
    <div style={{ maxWidth: 640 }}>
      <Title level={3}>Add Employee</Title>
      <Card>
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSubmit}
          initialValues={{ status: "active", hire_date: dayjs() }}
        >
          <Form.Item name="first_name" label="First Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="last_name" label="Last Name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email" rules={[{ required: true, type: "email" }]}>
            <Input />
          </Form.Item>
          <Form.Item name="country" label="Country" rules={[{ required: true }]}>
            <Select
              options={countries.map((c) => ({ value: c, label: c }))}
              onChange={handleCountryChange}
            />
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
          <Form.Item name="hire_date" label="Hire Date" rules={[{ required: true }]}>
            <DatePicker style={{ width: "100%" }} />
          </Form.Item>

          <Title level={5}>Initial Salary</Title>
          <Form.Item
            name={["initial_salary", "amount"]}
            label="Amount"
            rules={[{ required: true }]}
          >
            <InputNumber style={{ width: "100%" }} min={0.01} step={1000} />
          </Form.Item>
          <Form.Item
            name={["initial_salary", "currency"]}
            label="Currency"
            rules={[{ required: true }]}
          >
            <Select options={currencies.map((c) => ({ value: c, label: c }))} />
          </Form.Item>

          <Form.Item>
            <Button type="primary" htmlType="submit">
              Create Employee
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
}
