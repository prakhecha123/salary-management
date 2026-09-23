import client from "./client";

export const fetchEmployees = (params) =>
  client.get("/employees", { params }).then((res) => res.data);

export const fetchEmployee = (id) =>
  client.get(`/employees/${id}`).then((res) => res.data);

export const createEmployee = (payload) =>
  client.post("/employees", payload).then((res) => res.data);

export const updateEmployee = (id, payload) =>
  client.patch(`/employees/${id}`, payload).then((res) => res.data);

export const addSalaryRecord = (employeeId, payload) =>
  client.post(`/employees/${employeeId}/salary_records`, payload).then((res) => res.data);
