require('./lib/mass_matcher/oligo_comp')

class OligoCompSet
  
  include Enumerable
  
  def initialize (minimum_length, maximum_length, residue_array, derivative_array)
    @oligos = []
    minimum_length.upto(maximum_length) do |length|
      distributions = OligoCompSet.all_distributions(length,residue_array.length)
      distributions.each do |distribution|
        residue_hash = {}
        distribution.length.times { |index| residue_hash[residue_array[index]] = distribution[index] }
        derivative_array.each { |derivative| @oligos << OligoComp.new(residue_hash, derivative) }
      end
    end
  end
  
  def each(&block)
    @oligos.each(&block)
  end
  
  def self.all_distributions(num_objects,num_bins)
    distributions = []
    carry_over = false
    bins = Array.new(num_bins,0)
    begin
      bins[0] += 1
      bins.map! do |count|
        count += 1 if carry_over
        carry_over = false
        if count > num_objects
          carry_over = true
          count = 0
        end
        count
      end
      object_sum = 0
      bins.each { |count| object_sum += count }
      distributions << bins.clone if object_sum == num_objects
    end while (bins.last < num_objects)
    distributions
  end
  
end