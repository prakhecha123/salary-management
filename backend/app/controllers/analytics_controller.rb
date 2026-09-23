class AnalyticsController < ApplicationController
  def overview
    render json: {
      overall: PayrollAnalytics.overall,
      by_country: PayrollAnalytics.by_country,
      by_department: PayrollAnalytics.by_department
    }
  end
end
