 $(document).ready(function(){
    $.each(all_charts, function(chart_div, cfg){
      $.ajax({
        url: '/chart/'+cfg.url,
        container: chart_div,
        success: onChartDataRetrieved,
        error: function(){
          alert('Error loading '+chart_type+' chart');
        }
      });
    });
  });

  function onChartDataRetrieved(chart_config){
    var chart_type = this.container;
    chart_config.chart.renderTo = chart_type;
    all_charts[chart_type].chart = new Highcharts.Chart(addInteraction(chart_type, chart_config));
  }

  function addInteraction(chart_type, cfg_obj){
    if(chart_type.match(/_percent_/)){
          cfg_obj.yAxis.labels.formatter = function(){
            return (this.value*100)+'%';
          }
          cfg_obj.tooltip.formatter = function(){
            return this.x + '<br/>' + '<span style="color: ' + this.series.color+'">' + this.series.name+'</span> : <b>' +  Math.round(this.y*10000)/100 + '%</b>';
          }
    }
    return cfg_obj;
  }