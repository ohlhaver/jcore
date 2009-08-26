module JCore
  
  module Distance
    
    class << self
      
      #
      # Least Common Subsequence Distance
      # 
      def lcs_distance( seq1, seq2 )
        matrix = Array.new(seq1.size+1).collect!{ Array.new(seq2.size+1, 0) }
         seq1.size.times{ |i| matrix[i+1][0] = 0 }
         seq2.size.times{ |j| matrix[0][j+1] = 0 }
         seq1.size.times do |i|
           seq2.size.times do |j|
             matrix[i+1][j+1] = (seq1[i] == seq2[j]) ? ( matrix[i][j] + 1 ) : [ matrix[i][j+1], matrix[i+1][j] ].max 
           end
         end
         return matrix[seq1.size][seq2.size]
      end
      #
      # Levhenstein Edit Distance
      # Source: http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance
      #
      def edit_distance( seq1, seq2 )
        matrix = Array.new(seq1.size+1).collect!{ Array.new(seq2.size+1, 0) }
        seq1.size.times{ |i| matrix[i+1][0] = i+1 }
        seq2.size.times{ |j| matrix[0][j+1] = j+1 }
        seq1.size.times do |i|
          seq2.size.times do |j|
            matrix[i+1][j+1] = [ matrix[i][j+1]+1, matrix[i+1][j]+1, matrix[i][j] + (seq1[i] == seq2[j] ? 0 : 1) ].min
          end
        end
        matrix[seq1.size][seq2.size]
      end
      
    end
    
  end
  
end