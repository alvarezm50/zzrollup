class HighchartsController < ApplicationController

  def active_users_by_cohort
    f_chart_cfg = {
      :chart => {
        :renderTo => params[:action].gsub('_', '-'),
        :defaultSeriesType => 'area'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Cumulative Active Users (10+ Photos) by Cohort'
      },
      :subtitle => {
        :text => 'brought to you by ZZ guys'
      },
      :xAxis => {
        #:categories => ['1750', '1800', '1850', '1900', '1950', '1999', '2050'],
        :tickmarkPlacement => 'on',
        #:type => 'datetime',
        :title => {
          :enabled => false
        },
        :labels => {
            :rotation => -90,
            :align => 'right'
        }
      },
      :yAxis => {
        :title => {
          :text => 'Active Users (Add 10+ Photos/month)'
        },
      },
      :plotOptions => {
        :area => {
          :stacking => 'normal',
          :lineColor => '#666666',
          :lineWidth =>1,
          :marker => {
            :lineWidth =>1,
            :lineColor => '#666666'
          }
        }
      }
    }

    span = params[:span]
    span = span.nil? ? RollupTasks::DAILY_REPORT_INTERVAL : span.to_i

    @rollup_data = RollupTasks.rollup_raw_data(span)

    @rollup_data = @rollup_data.transpose
    
    x_axis = @rollup_data.delete_at(0)
    x_title = x_axis.delete_at(0)
    f_chart_cfg[:xAxis][:categories] = x_axis
    
    series = @rollup_data.select{ |row| row[0] =~ /Cohort\.photos_10\.\d/ }.map do |serie|
      name = serie.delete_at(0)
      {
        :name => name,
        :data => serie.map{|value| value.blank? ? 0 : value.to_i }
      }
    end
    f_chart_cfg[:series] = series
    

    render :json => {
      :type => params[:action],
      :config => f_chart_cfg
    }

  end

end
