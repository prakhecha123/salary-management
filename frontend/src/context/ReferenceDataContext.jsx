import { useEffect, useState } from "react";
import { fetchReferenceData } from "../api/referenceData";
import ReferenceDataContext from "./referenceDataContextInstance";

export function ReferenceDataProvider({ children }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchReferenceData()
      .then(setData)
      .catch((err) => setError(err));
  }, []);

  if (error) {
    return <div style={{ padding: 24 }}>Could not load reference data. Is the API running?</div>;
  }

  if (!data) {
    return null;
  }

  return <ReferenceDataContext.Provider value={data}>{children}</ReferenceDataContext.Provider>;
}
