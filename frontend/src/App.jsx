import { Routes, Route } from "react-router-dom";
import AppLayout from "./components/AppLayout";
import { ReferenceDataProvider } from "./context/ReferenceDataContext";
import EmployeeListPage from "./pages/EmployeeListPage";
import EmployeeDetailPage from "./pages/EmployeeDetailPage";
import NewEmployeePage from "./pages/NewEmployeePage";
import DashboardPage from "./pages/DashboardPage";

function App() {
  return (
    <ReferenceDataProvider>
      <Routes>
        <Route path="/" element={<AppLayout />}>
          <Route index element={<EmployeeListPage />} />
          <Route path="employees/new" element={<NewEmployeePage />} />
          <Route path="employees/:id" element={<EmployeeDetailPage />} />
          <Route path="dashboard" element={<DashboardPage />} />
        </Route>
      </Routes>
    </ReferenceDataProvider>
  );
}

export default App;
