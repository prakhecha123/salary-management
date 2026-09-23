import { Layout, Menu } from "antd";
import { Link, Outlet, useLocation } from "react-router-dom";

const { Header, Content } = Layout;

const NAV_ITEMS = [
  { key: "/", label: <Link to="/">Employees</Link> },
  { key: "/employees/new", label: <Link to="/employees/new">Add Employee</Link> },
  { key: "/dashboard", label: <Link to="/dashboard">Dashboard</Link> },
];

export default function AppLayout() {
  const location = useLocation();
  const selectedKey = NAV_ITEMS.find((item) => location.pathname.startsWith(item.key) && item.key !== "/")?.key ?? "/";

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header style={{ display: "flex", alignItems: "center", gap: 24 }}>
        <span style={{ color: "#fff", fontWeight: 600, fontSize: 16 }}>ACME Salary Management</span>
        <Menu
          theme="dark"
          mode="horizontal"
          selectedKeys={[selectedKey]}
          items={NAV_ITEMS}
          style={{ flex: 1, minWidth: 0 }}
        />
      </Header>
      <Content style={{ padding: 24 }}>
        <Outlet />
      </Content>
    </Layout>
  );
}
