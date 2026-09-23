import client from "./client";

export const fetchAnalyticsOverview = () => client.get("/analytics/overview").then((res) => res.data);
