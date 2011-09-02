module RollupData
  class HighchartConfig
    MAX_X_LABELS_AMOUNT = 30

    attr_accessor :subtitle, :y_axis, :x_axis, :legend_enabled, :legend_orientation, :type
    
    BASE_CONFIG = {
      :series => nil,
      :chart => {
        :renderTo => '',
        :defaultSeriesType => nil
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => nil
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => nil,
        :tickmarkPlacement => 'on',
        :title => {
          :enabled => false
        },
        :labels => {
          :rotation => -90,
          :align => 'right'
        }
      },
      :yAxis => {
        :min => 0,
        :title => {
          :text => nil
        },
        :labels => { :formatter => nil }
      },
      :tooltip => { :formatter => nil }
    }

    def initialize(datasource, title, type = :line)
      @datasource = datasource
      @title = title
      @type = type.to_s
      yield self if block_given?
    end

    def build_final
      cfg = BASE_CONFIG.dup
      cfg[:title][:text] = @title
      cfg[:chart][:defaultSeriesType] = @type
      cfg[:xAxis][:categories] = @datasource.categories
      cfg[:legend][:enabled] = @legeng_enabled

      if @subtitle
        cfg.deep_merge!(:subtitle => { :text => @subtitle })
      end
      if @y_axis
        cfg[:yAxis][:title][:text] = @y_axis
      end
      if @x_axis
        cfg[:xAxis][:title][:enabled] = true
        cfg[:xAxis][:title][:text] = @x_axis
      end
      if @datasource.categories.size > MAX_X_LABELS_AMOUNT
        cfg[:xAxis][:labels][:step] = (@datasource.categories.size.to_f / MAX_X_LABELS_AMOUNT).ceil
      end
      if @datasource.percent_view
        cfg.deep_merge!(
          :tooltip => { :formatter => nil },
          :yAxis => { :labels => { :formatter => nil } }
        )
      end

      #if @datasource.
      #  cfg.deep_merge!()
      #end

      cfg
    end

  end
end