defmodule Phenotype.Actuator do 
  # Expected inputs are currently not received inputs. 
  # Accumulator is sum of received inputs.
	defstruct id: nil, cortex_pid: nil, name: nil, vector_length: 1, fanin_pids: [], expected_inputs: [], accumulator: 0, sim_pid: nil
	use GenServer

	def start_link(actuator, cortex_pid) do 
		GenServer.start_link(__MODULE__,[actuator, cortex_pid] , [])
	end

	def init([actuator, cortex_pid]) do 
		state = %Phenotype.Actuator{id: actuator.id, cortex_pid: cortex_pid, name: (actuator.name), vector_length: actuator.vector_length }
    # IO.puts "Initilizing #{__MODULE__} #{state.id} #{inspect self()}"
		{:ok, state}
	end

	def update(pid, fanins, sim_pid) do 
		GenServer.cast(pid, {:update, fanins, sim_pid})
	end

  def terminate(pid) do 
    GenServer.cast(pid, :terminate)
  end

  # I dont give super caller for this one, as it will be
  # mistakenly activated by Neuron, (which expects to send
  # the data to another neuron... :)
  def handle_cast({:forward, data, origin}, state) do 
    # As expected we receive bunch of data
    expected_inputs = List.delete(state.expected_inputs, origin)
    value = Enum.reduce(data, 0, fn(x,acc) -> acc + x end)
    state = %Phenotype.Actuator{state| expected_inputs: expected_inputs, accumulator: state.accumulator + value}

    if length(expected_inputs) == 0 do 
      #We've completed the job, Hourray :)
      {:result, fitness, should_stop} = GenServer.call(state.sim_pid, {:act, state.accumulator})
      # Notifying cortex of our success
      Phenotype.Cortex.actuator_finished(state.cortex_pid, self(),fitness, should_stop)
      # Dont forget to reset state to waiting job :)
      {:noreply, %Phenotype.Actuator{state | expected_inputs: state.fanin_pids, accumulator: 0}}
    else
      {:noreply, state}
    end
  end

  def handle_cast(:terminate, state) do
    IO.puts "#{__MODULE__} #{state.id} Imposed termination"
    {:stop, :normal, state}
  end

	def handle_cast({:update, fanins, sim_pid}, state) do 
		{:noreply, %Phenotype.Actuator{state| fanin_pids: fanins, sim_pid: sim_pid}}
	end
end
