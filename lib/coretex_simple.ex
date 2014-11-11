defmodule CortexSimple do 
	def create() do 
		weights = [:random.uniform()-0.5,:random.uniform()-0.5,:random.uniform()-0.5]
		n_pid = spawn_link(CortexSimple, :neuron, [weights,:undefined,:undefined])
		s_pid = spawn_link(CortexSimple, :sensor, [n_pid])
		a_pid = spawn_link(CortexSimple, :actuator, [n_pid])
		send(n_pid, {:init, s_pid, a_pid})
		Process.register(:cortex, spawn_link(CortexSimple, :cortex, [s_pid, n_pid, a_pid]))
	end

	def neuron(weights, sensor_pid, actuator_pid) do 
		receive do 
			{^sensor_pid, :forward, inputs} ->
				IO.puts "Thinking: inputs #{ inspect inputs } using weights #{ inspect weights }"
				dp = dot(inputs, weights, 0)
				output = [:math.tanh(dp)]
				send(actuator_pid, {self(), :forward, output})
				neuron(weights, sensor_pid, actuator_pid)
			{:init, s_pid, a_pid} ->
				neuron(weights, s_pid, a_pid)
			:terminate ->
				:ok
		end
	end

	def sensor(neuron_pid) do 
		receive do 
			:sync ->
				signal = [:random.uniform(), :random.uniform()]
				IO.puts "Sensing signal #{inspect signal}"
				send(neuron_pid, {self(), :forward, signal})
				sensor(neuron_pid)
			:terminate ->
				:ok
		end	
	end

	def actuator(neuron_pid) do 
		receive do 
			{^neuron_pid, :forward, output} ->
				act(output)
				actuator(neuron_pid)
			:terminate ->
				:ok
		end
	end

	def cortex() do 
		receive do 

		end
	end

	def act(value) do 
		IO.puts "Acting with value #{value}"
	end

	def dot([i | inputs], [w | weights], acc) do 
		dot(inputs, weights, i*w + acc)
	end

	def dot([],[], acc) do
		acc
	end

	def dot([], [bias], acc) do
		acc + bias
	end
end