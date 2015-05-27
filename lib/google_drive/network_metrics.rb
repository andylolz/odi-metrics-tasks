class NetworkMetrics

  @queue = :metrics

  extend MetricsHelper
  extend GoogleDriveHelper

  def self.perform
    current_year  = DateTime.now.year
    current_month = DateTime.now.month
    {
      "current-year-reach"                   => reach(current_year),
      "cumulative-reach"                     => reach(nil),
      "current-year-pr-pieces"               => pr_pieces(current_year),
      "current-year-events-hosted"           => events_hosted(current_year),
      "current-year-people-trained"          => people_trained(current_year, current_month),
      "cumulative-people-trained"            => people_trained(nil, nil),
      "current-year-network-size"            => network_size(current_year, current_month),
      "cumulative-network-size"              => network_size(nil, nil)
    }.each_pair do |metric, value|
      store_metric metric, DateTime.now, value
    end
    clear_cache!
  end

  def self.reach(year = nil)
    if year.nil?
      years.map{|year| reach(year)}.inject do |memo, reach|
        memo = {
          total: memo[:total] + reach[:total],
          breakdown: {
            active:  memo[:breakdown][:active] + reach[:breakdown][:active],
            passive: memo[:breakdown][:passive] + reach[:breakdown][:passive],
          }
        }
      end
    else
      {
        total:   metrics_cell("Active Reach", year, Proc.new { |x| integize(x) }) +
                 metrics_cell("Passive Reach", year, Proc.new { |x| integize(x) }),
        breakdown: {
          active:  metrics_cell("Active Reach", year, Proc.new { |x| integize(x) }),
          passive: metrics_cell("Passive Reach", year, Proc.new { |x| integize(x) }),
        }
      }
    end
  end

  def self.pr_pieces(year)
    block = Proc.new { |x| integize(x) }
    metrics_cell('PR Pieces', year, block)
  end

  def self.events_hosted(year)
    block = Proc.new { |x| integize(x) }
    metrics_cell('Events hosted', year, block)
  end

  def self.people_trained(year, month)
    if year.nil? && month.nil?
      years.map{|year| people_trained(year, 12)}.inject(0) do |memo, trained|
        memo += trained[:total]
      end
    else
      block = Proc.new { |x| integize(x) }
      h     = {
          commercial:     'Commercial people trained',
          non_commercial: 'Non-commercial people trained'
      }
      data = extract_metrics h, year, month, block
      if cell_location(year, "People trained")
        data[:total] = metrics_cell('People trained', year, block)
      else
        data[:total] = data[:commercial][:actual] + data[:non_commercial][:actual]
      end
      data
    end
  end

  def self.network_size(year, month)
    block = Proc.new { |x| integize(x) }
    if year.nil? && month.nil?
      years.inject(0) do |memo, year|
        memo += metrics_total 'Network size', year, block
      end
    else
      if cell_location year, 'Partners'
        h     = {
            partners:   'Partners',
            sponsors:   'Sponsors',
            supporters: 'Supporters',
            startups:   'Startups',
            nodes:      'Nodes',
            affiliates: 'Affiliates',
        }
        extract_metrics h, year, month, block
      else
        metric_with_target 'Network size', year, month, block
      end
    end
  end

end
