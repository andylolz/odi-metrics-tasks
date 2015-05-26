class FinancialMetrics

  @queue = :metrics

  extend MetricsHelper
  extend GoogleDriveHelper

  def self.perform
    current_year  = DateTime.now.year
    current_month = DateTime.now.month
    {
      "cash-reserves"                        => cash_reserves(current_year),
      "current-year-value-unlocked"          => value(current_year),
      "cumulative-value-unlocked"            => value(nil),
      "current-year-income"                  => income(current_year, current_month),
      "cumulative-income"                    => income(nil, nil),
      "cumulative-bookings"                  => bookings(nil, nil),
      "current-year-kpi-performance"         => kpis(current_year),
      "current-year-grant-funding"           => grant_funding(current_year, current_month),
      "current-year-bookings"                => bookings(current_year, current_month),
      "current-year-bookings-by-sector"      => bookings_by_sector(current_year, current_month),
      "current-year-headcount"               => headcount(current_year, current_month),
      "current-year-burn"                    => burn_rate(current_year, current_month),
      "current-year-ebitda"                  => ebitda(current_year, current_month),
      "current-year-total-costs"             => total_costs(current_year, current_month),
    }.each_pair do |metric, value|
      store_metric metric, DateTime.now, value
    end
    clear_cache!
  end

  def self.value(year = nil)
    if year.nil?
      years.inject(0) { |total, year| total += value(year) }
    else
      metrics_cell('Value unlocked', year, Proc.new {|x| integize(x) })
    end
  end

  def self.kpis(year)
    metrics_cell('KPI percentage', year, Proc.new {|x| floatize(x) }).round(1)
  end

  def self.cash_reserves(year)
    metrics_cell('Cash reserves', year, Proc.new {|x| floatize(x) })
  end

  def self.bookings(year, month)
    block = Proc.new { |x| integize(x) }
    if year.nil? && month.nil?
      years.inject(0) do |memo, year|
        memo += metrics_total 'Total bookings', year, block
      end
    else
      extract_metric 'Total bookings', year, month, block
    end
  end

  def self.income(year, month)
    if year.nil? && month.nil?
      years.inject(0) do |memo, year|
        memo += metrics_cell 'Income', year, Proc.new { |x| integize(x) }, 'actual'
      end
    else
      metric_with_target 'Income', year, month, Proc.new {|x| floatize(x) }
    end
  end

  def self.grant_funding(year, month)
    block = Proc.new { |x| floatize(x) }
    metric_with_target 'Grant Funding', year, month, block
  end

  def self.bookings_by_sector(year, month)
    block = Proc.new { |x| floatize(x) }
    Hash[
        [
        :research,
        :training,
        :projects,
        :network
    ].map do |item|
      [item, extract_metrics(
          {
              commercial: "Commercial #{item.to_s} bookings",
              non_commercial: "Non-commercial #{item.to_s} bookings"
          }, year, month, block)]
        end
    ]
  end

  def self.headcount(year, month)
    block = Proc.new { |x| x.is_a?(Array) ? floatize(x[month-1]) : floatize(x) }
    metric_with_target 'Headcount', year, month, block
  end

  def self.burn_rate(year, month)
    block = Proc.new do |data|
      data = data.slice(0,month)
      nonzero = data.select{|val| val.to_f > 0}
      divisor = [nonzero.length, 3].min
      sum = nonzero.last(3).map{ |x| floatize(x) }.inject(0.0){|sum,val| sum += val} / divisor
    end
    metrics_cell 'Burn', year, block
  end

  def self.ebitda(year, month)
    block = Proc.new { |x| x.is_a?(Array) ? x.inject(0.0) { |s,v| s += floatize(v) } : floatize(x) }
    metric_with_target 'EBITDA', year, month, block
  end

  def self.total_costs(year, month)
    block = Proc.new { |x| floatize(x) }
    breakdown = {
      variable: extract_metrics(
                    {
                        research: 'Research costs',
                        training: 'Training costs',
                        projects: 'Projects costs',
                        network:  'Network costs'
                    }, year, month, block),
      fixed:    extract_metrics(
                    {
                        staff:                  'Staff costs',
                        associates:             'Associate costs',
                        office_and_operational: 'Office and operational costs',
                        delivery:               'Delivery costs',
                        communications:         'Communications costs',
                        professional_fees:      'Professional fees costs',
                        software:               'Software costs'
                    }, year, month, block)
    }
    variable = metric_with_target("Variable costs", year, month, block)
    fixed    = metric_with_target("Fixed costs", year, month, block)
    # Smoosh it all together
    {
        actual:        variable[:actual] + fixed[:actual],
        annual_target: variable[:annual_target] + fixed[:annual_target],
        ytd_target:    variable[:ytd_target] + fixed[:ytd_target],
        breakdown: breakdown
    }
  end

end
