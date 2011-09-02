module RollupData
  module Colorization

    TYPE_COLORS = {
      :album => '#AA4643', #red/maroon
      :photo => '#4572A7', #blue
      :user => '#89A54E', #green
      :twitter => '#AA4643', #red/maroon
      :email => '#4572A7', #blue
      :facebook => '#89A54E' #green
    }

    def colorize!(serie)
      return if !@colorize || serie[:color]
      if serie[:type]
        serie[:color] = TYPE_COLORS[serie[:type]]
      elsif type = serie[:name].scan(/(#{TYPE_COLORS.keys.join('|')})/i).flatten.last
        serie[:color] = TYPE_COLORS[type.downcase.to_sym]
      end
    end


  end
end