class NetworkMetrics

  @queue = :metrics

  extend MetricsHelper
  extend GoogleDriveHelper

  def self.perform
    current_year  = DateTime.now.year
    current_month = DateTime.now.month
    {
      "current-year-reach"                   => reach(current_year, current_month),
      "cumulative-reach"                     => reach(nil, nil),
      "current-year-pr-pieces"               => pr_pieces(current_year),
      "current-year-events-hosted"           => events_hosted(current_year),
      "current-year-people-trained"          => people_trained(current_year, current_month),
      "cumulative-people-trained"            => people_trained(nil, nil),
      "current-year-trainers-trained"        => trainers_trained(current_year, current_month),
      "current-year-network-size"            => network_size(current_year, current_month),
      "cumulative-network-size"              => network_size(nil, nil)
    }.each_pair do |metric, value|
      store_metric metric, DateTime.now, value
    end
    clear_cache!
  end

  def self.reach(year = nil, month = nil)
    total_block = Proc.new { |x| x.class == Hash ? x[:actual] : x }
    if year.nil? && month.nil?
      years.map{|year| reach(year, 12)}.inject do |memo, reach|
        memo = {
          total: total_block.call(memo[:total]) + total_block.call(reach[:total]),
          breakdown: {
            active:  total_block.call(memo[:breakdown][:active]) + total_block.call(reach[:breakdown][:active]),
            passive: total_block.call(memo[:breakdown][:passive]) + total_block.call(reach[:breakdown][:passive]),
          }
        }
      end
    else
      integize_block = Proc.new { |x| integize(x) }
      active  = extract_metric "Active Reach", year, month, integize_block
      passive = extract_metric "Passive Reach", year, month, integize_block
      if active.class == Hash && passive.class == Hash
        total = active.inject({}) do |data, (k, v)|
          data[k] = v + passive[k]
          data
        end
      else
        total = total_block.call(active) + total_block.call(passive)
      end
      {
        total: total,
        breakdown: {
          active:  active,
          passive: passive,
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
        memo += trained.has_key?(:actual) ? trained[:actual] : trained[:total]
      end
    else
      data = {}
      block = Proc.new { |x| integize(x) }
      if cell_location year, 'Commercial people trained'
        h     = {
            commercial:     'Commercial people trained',
            non_commercial: 'Non-commercial people trained'
        }
        data = extract_metrics h, year, month, block
      end
      if cell_location year, 'People trained'
        total = extract_metric 'People trained', year, month, block
        if not total.is_a? Hash
          total = {:total => total}
        end
        data.merge!(total)
      else
        data[:total] = data[:commercial][:actual] + data[:non_commercial][:actual]
      end
      data
    end
  end

  def self.trainers_trained(year, month)
    extract_metric 'Trainers trained', year, month, Proc.new { |x| integize(x) }
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
