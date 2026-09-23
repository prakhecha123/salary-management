import { useContext } from "react";
import ReferenceDataContext from "./referenceDataContextInstance";

export default function useReferenceData() {
  const context = useContext(ReferenceDataContext);
  if (!context) {
    throw new Error("useReferenceData must be used within a ReferenceDataProvider");
  }
  return context;
}
