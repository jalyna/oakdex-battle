module Oakdex
  class Battle
    # Represents Pokemon Move with PP
    class Move
      def initialize(move_type, pp, max_pp)
        @move_type  = move_type
        @pp         = pp
        @max_pp     = max_pp
      end
    end
  end
end
