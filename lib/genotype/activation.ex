defmodule Genotype.Activation do 
  # This module aims at grouping neurons activation functions ....
  # There should be some way to select a method from these :)  
  def tanh(input) do 
    :math.tanh(input)
  end

end
