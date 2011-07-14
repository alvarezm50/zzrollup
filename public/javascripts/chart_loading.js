 $(document).ready(function(){
    $.each(all_charts, function(chart_div, cfg){
      var button = $('<div><a href="/chart/'+ cfg.url.replace('.json', '.xls') +'"><img src="/images/blue-document-excel-table.png" title="Download XLS"/></a><div>');
      var container = $('#'+chart_div);
      var pos = container.offset();
      button.css( {"position": 'absolute', "zIndex": 5000, "left": (pos.left+50) + "px", "top": (pos.top+10) + "px" } );
      container.before(button);
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
    if(chart_type.match(/_perc(ent)?_/)){
          cfg_obj.yAxis.labels.formatter = function(){
            return (this.value*100)+'%';
          }
          cfg_obj.tooltip.formatter = function(){
            return this.x + '<br/>' + '<span style="color: ' + this.series.color+'">' + this.series.name+'</span> : <b>' +  Math.round(this.y*10000)/100 + '%</b>';
          }
    }
    else if(chart_type.match(/^pie_/)){
          cfg_obj.tooltip.formatter = function(){
            return this.point.name+' : <b>' +  Math.round(this.y*10000)/100 + '%</b>';
          }
          cfg_obj.plotOptions.pie.dataLabels.formatter = function(){
              return Math.round(this.y*10000)/100 + '%';
          }
    }
    return cfg_obj;
  }