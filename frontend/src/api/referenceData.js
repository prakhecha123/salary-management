import client from "./client";

export const fetchReferenceData = () => client.get("/reference_data").then((res) => res.data);
