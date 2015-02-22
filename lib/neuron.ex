defmodule Neuron do 

	def create do 
		weights = [:random.uniform()-0.5,:random.uniform()-0.5,:random.uniform()-0.5]
		Process.register(spawn_link(Neuron, :loop, [weights]), :neuron)
	end

	def loop(weights) do 
		receive do
			{from, inputs} ->
				IO.puts "Processing inputs #{ inspect inputs } using weights #{ inspect weights }"
				dp = dot(inputs, weights, 0)
				output = [:math.tanh(dp)]
				send(from, {:result, output})
				loop(weights)
			_ ->
				IO.puts "Unexpected inputs"
				loop(weights)
		end
	end

	def dot([i | inputs], [w | weights], acc) do 
		dot(inputs, weights, i*w + acc)
	end

	def dot([], [bias], acc) do
		acc + bias
	end

	def sense(signal) do 
		case is_list(signal) and (length(signal) == 2) do
			true ->
				send(:neuron, {self(),signal})
				receive do
					{:result,output} ->
						IO.puts " Output: #{inspect output }"
					_ ->
						IO.puts "Unexpected results ..."
				end
			false ->
				IO.puts "The Signal must be a list of length 2"
		end
	end
end
