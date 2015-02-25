defmodule Phenotype.Neuron do 
# Note that input pids is an array of tuples {pid, weight}
  defstruct id: nil, layer: 0, cortex_pid: nil, activation_function: nil, input_pids: [], output_pids: [], expected_inputs: [], accumulator: 0
	use GenServer

	def start_link(neuron, cortex_pid) do 
		GenServer.start_link(__MODULE__, [neuron, cortex_pid], [])
	end

	def init([neuron, cortex_pid]) do 
		state = %Phenotype.Neuron{id: neuron.id, layer: neuron.layer, cortex_pid: cortex_pid, activation_function: (neuron.activation_function), accumulator: 0}
		IO.puts "Initilizing #{__MODULE__} #{state.id} #{inspect self()}"
		{:ok, state}
	end

	def update(pid, inputs, outputs) do 
		GenServer.cast(pid, {:update, inputs, outputs})
	end

  def terminate(pid) do 
    GenServer.cast(pid, :terminate)
  end

  def forward(pid, data, caller) do 
    GenServer.cast(pid, {:forward, data, caller})
  end

  def fetch_backup_info(pid) do 
    GenServer.call(pid, :backup_info)
  end

  def handle_call(:backup_info, from, state) do 
    # back up info are minimals ... 
    # id, and updated weights ...

    {:reply, {state.id, state.input_pids}, from, state} 
  end

  # This is main neuron entrypoint. 
  # It could be called by another neuron, or by a Sensor.
  def handle_cast({:forward, data, origin_pid}, state) do 
    state = process_input(state, origin_pid, data)
    if length(state.expected_inputs) == 1 do 
      [{:biais, weight, -1}] = state.expected_inputs
      IO.puts "Neuron #{state.id} finished is job !" 
      # we proudly announce next layer that we've completed our job :)
      # Note: apply(module, function(as atom), [params])
      # Note: target expects an array of info :)
      real_value = apply(__MODULE__, state.activation_function,[state.accumulator + weight])
      for n <- state.output_pids do 
        IO.puts "Phenotype.Neuron.forward(#{inspect n},#{inspect [real_value]}, self())"
        Phenotype.Neuron.forward(n,[real_value], self()) 
      end

      # we reset accumulator and expected inputs status.
      state = %Phenotype.Neuron{state| expected_inputs: state.input_pids, accumulator: 0}
    end
    {:noreply, state}
  end

  def handle_cast(:terminate, state) do
    IO.puts "#{__MODULE__} #{state.id} Imposed termination"
    {:stop, :normal, state}
  end

	def handle_cast({:update, inputs, outputs}, state) do 
		{:noreply, %Phenotype.Neuron{state| input_pids: inputs, output_pids: outputs, expected_inputs: inputs}}
	end

  def process_input(state, origin_pid, data) do 
    {expected, value} = find(state.expected_inputs, origin_pid, data, [])
    %Phenotype.Neuron{state| expected_inputs: expected, accumulator: state.accumulator + value}
  end

  # World should be so fine that for each input there should be enough weight given. 
  # expect to be one more weight as biais (should be set as such by genotype ..., aint the case right now... bad :)
  def find([{pid, weights, _id} = input | rest], origin_pid, data, acc) do 
    if pid == origin_pid do 
      {rest ++ acc, dot(data, weights, 0) }
    else
      find(rest, origin_pid, data, [input|acc])
    end
  end

  def find([], _,_, acc) do
    IO.puts "This should NEVER happend... Neuron has been contacted by someone unexpected !"
    {:error, :no_match_found}
  end

	
  def dot([i | inputs], [w | weights], acc) do 
		dot(inputs, weights, i*w + acc)
	end

	def dot([], [], acc) do
		acc 
	end

  def tanh(value) do 
    :math.tanh(value)
  end
end
